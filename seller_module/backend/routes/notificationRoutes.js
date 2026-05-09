const express = require('express');
const router = express.Router();
const Notification = require('../models/Notification');
const { protect } = require('../middleware/auth');

// GET /api/notifications - Get user's notifications
router.get('/', protect, async (req, res) => {
  try {
    const notifications = await Notification.find({ userId: req.sellerId })
      .populate('itemId', 'title imageUrl price category')
      .sort({ createdAt: -1 })
      .limit(50);
    res.json(notifications);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// GET /api/notifications/unread-count - Get unread count
router.get('/unread-count', protect, async (req, res) => {
  try {
    const count = await Notification.countDocuments({ userId: req.sellerId, read: false });
    res.json({ count });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// PATCH /api/notifications/:id/read - Mark single notification as read
router.patch('/:id/read', protect, async (req, res) => {
  try {
    await Notification.findOneAndUpdate(
      { _id: req.params.id, userId: req.sellerId },
      { read: true }
    );
    res.json({ message: 'Marked as read' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// PATCH /api/notifications/read-all - Mark all as read
router.patch('/read-all', protect, async (req, res) => {
  try {
    await Notification.updateMany(
      { userId: req.sellerId, read: false },
      { read: true }
    );
    res.json({ message: 'All marked as read' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// DELETE /api/notifications/:id - Delete single notification
router.delete('/:id', protect, async (req, res) => {
  try {
    await Notification.findOneAndDelete({ _id: req.params.id, userId: req.sellerId });
    res.json({ message: 'Notification deleted' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;

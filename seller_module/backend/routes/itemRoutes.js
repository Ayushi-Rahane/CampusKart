const express = require('express');
const router = express.Router();
const Item = require('../models/Item');
const User = require('../models/User');
const { protect } = require('../middleware/auth');
const { upload } = require('../config/cloudinary');

// POST /api/items - Add new item
router.post('/', protect, upload.single('image'), async (req, res) => {
  try {
    const { title, description, price, category } = req.body;
    const newItem = await Item.create({
      title,
      description,
      price,
      category,
      imageUrl: req.file.path, // Cloudinary URL
      sellerId: req.sellerId
    });
    res.status(201).json(newItem);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});
// GET /api/items - Get all items
router.get('/', protect, async (req, res) => {
  try {
    const items = await Item.find().sort({ createdAt: -1 });
    res.json(items);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// GET /api/items/my - Get seller's items
router.get('/my', protect, async (req, res) => {
  try {
    const items = await Item.find({ sellerId: req.sellerId }).sort({ createdAt: -1 });
    res.json(items);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// GET /api/items/:id - Get single item with seller info
router.get('/:id', protect, async (req, res) => {
  try {
    const item = await Item.findById(req.params.id);
    if (!item) return res.status(404).json({ message: 'Item not found' });
    const seller = await User.findById(item.sellerId).select('name email');
    const itemObj = item.toObject();
    itemObj.seller = seller ? { name: seller.name, email: seller.email } : null;
    res.json(itemObj);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// PUT /api/items/:id - Update item
router.put('/:id', protect, async (req, res) => {
  try {
    const item = await Item.findById(req.params.id);
    if (!item || item.sellerId.toString() !== req.sellerId) {
      return res.status(401).json({ message: 'Not authorized' });
    }
    const updatedItem = await Item.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.json(updatedItem);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// DELETE /api/items/:id
router.delete('/:id', protect, async (req, res) => {
  try {
    await Item.findOneAndDelete({ _id: req.params.id, sellerId: req.sellerId });
    res.json({ message: 'Item removed' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// PATCH /api/items/:id/sold
router.patch('/:id/sold', protect, async (req, res) => {
  try {
    const item = await Item.findOneAndUpdate(
      { _id: req.params.id, sellerId: req.sellerId },
      { status: 'sold' },
      { new: true }
    );
    res.json(item);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;

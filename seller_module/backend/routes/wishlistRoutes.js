const express = require('express');
const router = express.Router();
const Wishlist = require('../models/Wishlist');
const Item = require('../models/Item');
const { protect } = require('../middleware/auth');

// POST /api/wishlist/:itemId - Add item to wishlist
router.post('/:itemId', protect, async (req, res) => {
  try {
    const existing = await Wishlist.findOne({ userId: req.sellerId, itemId: req.params.itemId });
    if (existing) {
      return res.status(400).json({ message: 'Item already in wishlist' });
    }
    const entry = await Wishlist.create({ userId: req.sellerId, itemId: req.params.itemId });
    res.status(201).json(entry);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// DELETE /api/wishlist/:itemId - Remove item from wishlist
router.delete('/:itemId', protect, async (req, res) => {
  try {
    await Wishlist.findOneAndDelete({ userId: req.sellerId, itemId: req.params.itemId });
    res.json({ message: 'Removed from wishlist' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// GET /api/wishlist - Get user's wishlist items
router.get('/', protect, async (req, res) => {
  try {
    const wishlistEntries = await Wishlist.find({ userId: req.sellerId }).populate({
      path: 'itemId',
      model: 'Item',
    });
    // Return the actual item objects
    const items = wishlistEntries
      .filter(entry => entry.itemId != null)
      .map(entry => entry.itemId);
    res.json(items);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// GET /api/wishlist/check/:itemId - Check if item is in wishlist
router.get('/check/:itemId', protect, async (req, res) => {
  try {
    const entry = await Wishlist.findOne({ userId: req.sellerId, itemId: req.params.itemId });
    res.json({ isWishlisted: !!entry });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;

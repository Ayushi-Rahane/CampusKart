const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const Item = require('../models/Item');
const { protect } = require('../middleware/auth');
const { upload } = require('../config/cloudinary');

// GET /api/users/profile - Get logged-in user profile with stats
router.get('/profile', protect, async (req, res) => {
  try {
    const user = await User.findById(req.sellerId).select('-password');
    if (!user) return res.status(404).json({ message: 'User not found' });

    // Get purchase history (items where buyerId is me)
    const purchases = await Item.find({ buyerId: req.sellerId }).sort({ createdAt: -1 });
    
    // Get sell history (items where sellerId is me and status is sold)
    const sales = await Item.find({ sellerId: req.sellerId, status: 'sold' }).sort({ createdAt: -1 });

    res.json({
      profile: user,
      purchases,
      sales,
      averageRating: calculateAverageRating(user.ratings)
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// PUT /api/users/profile - Update profile details
router.put('/profile', protect, async (req, res) => {
  try {
    const { name, phone, address } = req.body;
    const user = await User.findById(req.sellerId);
    
    if (name) user.name = name;
    if (phone !== undefined) user.phone = phone;
    if (address !== undefined) user.address = address;

    await user.save();
    res.json({ message: 'Profile updated', user: { name: user.name, phone: user.phone, address: user.address } });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// PUT /api/users/password - Change password
router.put('/password', protect, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const user = await User.findById(req.sellerId);

    const isMatch = await bcrypt.compare(currentPassword, user.password);
    if (!isMatch) return res.status(400).json({ message: 'Invalid current password' });

    user.password = newPassword;
    await user.save();
    res.json({ message: 'Password updated successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// GET /api/users/:id - Get public seller profile
router.get('/:id', protect, async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password -phone -address');
    if (!user) return res.status(404).json({ message: 'User not found' });

    // Populate the buyer names in the ratings
    const populatedUser = await User.populate(user, { path: 'ratings.buyerId', select: 'name' });
    
    const availableItems = await Item.find({ sellerId: req.params.id, status: 'available' }).sort({ createdAt: -1 });
    const soldItems = await Item.find({ sellerId: req.params.id, status: 'sold' }).sort({ createdAt: -1 });

    res.json({
      seller: {
        _id: populatedUser._id,
        name: populatedUser.name,
        email: populatedUser.email,
        createdAt: populatedUser.createdAt,
        ratings: populatedUser.ratings,
        averageRating: calculateAverageRating(populatedUser.ratings)
      },
      availableItems,
      soldItems
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// POST /api/users/:id/rate - Rate a seller
router.post('/:id/rate', protect, upload.single('image'), async (req, res) => {
  try {
    const { rating, feedback, itemId } = req.body;
    const sellerId = req.params.id;
    const buyerId = req.sellerId;

    if (sellerId === buyerId) {
      return res.status(400).json({ message: "You cannot rate yourself" });
    }

    const seller = await User.findById(sellerId);
    if (!seller) return res.status(404).json({ message: 'Seller not found' });

    // Check if buyer has already rated this item
    const existingRating = seller.ratings.find(r => r.itemId && r.itemId.toString() === itemId && r.buyerId.toString() === buyerId);
    if (existingRating) {
      return res.status(400).json({ message: "You have already rated this transaction" });
    }

    seller.ratings.push({
      buyerId,
      itemId,
      rating,
      feedback,
      imageUrl: req.file ? req.file.path : ''
    });

    await seller.save();
    res.status(201).json({ message: 'Rating submitted successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

function calculateAverageRating(ratings) {
  if (!ratings || ratings.length === 0) return 0;
  const sum = ratings.reduce((acc, curr) => acc + curr.rating, 0);
  return (sum / ratings.length).toFixed(1);
}

module.exports = router;

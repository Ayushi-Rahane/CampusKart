const mongoose = require('mongoose');

const wishlistSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  itemId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Item',
    required: true,
  },
  addedAt: { type: Date, default: Date.now },
});

// Ensure a user can only add an item to wishlist once
wishlistSchema.index({ userId: 1, itemId: 1 }, { unique: true });

module.exports = mongoose.model('Wishlist', wishlistSchema);

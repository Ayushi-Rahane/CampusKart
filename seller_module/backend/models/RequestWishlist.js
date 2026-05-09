const mongoose = require('mongoose');

const requestWishlistSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  itemName: { type: String, required: true, trim: true },
  category: { type: String, default: '' },
  description: { type: String, default: '' },
  // Stores lowercase keywords derived from itemName for matching
  keywords: [{ type: String }],
  // Whether a matching item has been found
  matched: { type: Boolean, default: false },
  matchedItemId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Item',
    default: null,
  },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('RequestWishlist', requestWishlistSchema);

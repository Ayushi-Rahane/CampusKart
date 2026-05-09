const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  type: {
    type: String,
    enum: ['item_available', 'general'],
    default: 'general',
  },
  title: { type: String, required: true },
  message: { type: String, required: true },
  // Link to the item that matched
  itemId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Item',
    default: null,
  },
  // Link back to the request wishlist entry
  requestWishlistId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'RequestWishlist',
    default: null,
  },
  read: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Notification', notificationSchema);

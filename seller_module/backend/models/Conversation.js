const mongoose = require('mongoose');

const conversationSchema = new mongoose.Schema({
  participants: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  }],
  itemId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Item',
    required: true,
  },
  lastMessage: { type: String, default: '' },
  updatedAt: { type: Date, default: Date.now },
}, { timestamps: true });

// Index for quick lookup of conversations by participants and item
conversationSchema.index({ participants: 1, itemId: 1 });

module.exports = mongoose.model('Conversation', conversationSchema);

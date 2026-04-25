const express = require('express');
const router = express.Router();
const Conversation = require('../models/Conversation');
const Message = require('../models/Message');
const User = require('../models/User');
const Item = require('../models/Item');
const { protect } = require('../middleware/auth');

// POST /api/chat/start - Start or get existing conversation for an item with a seller
router.post('/start', protect, async (req, res) => {
  try {
    const { sellerId, itemId } = req.body;
    const buyerId = req.sellerId; // current logged-in user (named sellerId in auth middleware)

    if (buyerId === sellerId) {
      return res.status(400).json({ message: "You can't chat with yourself" });
    }

    // Check if conversation already exists between these two users for this item
    let conversation = await Conversation.findOne({
      participants: { $all: [buyerId, sellerId] },
      itemId: itemId,
    });

    if (!conversation) {
      conversation = await Conversation.create({
        participants: [buyerId, sellerId],
        itemId: itemId,
      });
    }

    res.json({ conversationId: conversation._id });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// GET /api/chat/conversations - Get all conversations for the logged-in user
router.get('/conversations', protect, async (req, res) => {
  try {
    const userId = req.sellerId;
    const conversations = await Conversation.find({
      participants: userId,
    }).sort({ updatedAt: -1 });

    // Populate with other user's info and item info
    const result = [];
    for (const conv of conversations) {
      const otherUserId = conv.participants.find(p => p.toString() !== userId);
      const otherUser = await User.findById(otherUserId).select('name email');
      const item = await Item.findById(conv.itemId).select('title imageUrl price');

      result.push({
        _id: conv._id,
        otherUser: otherUser ? { _id: otherUser._id, name: otherUser.name, email: otherUser.email } : null,
        item: item ? { _id: item._id, title: item.title, imageUrl: item.imageUrl, price: item.price } : null,
        lastMessage: conv.lastMessage,
        updatedAt: conv.updatedAt,
      });
    }

    res.json(result);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// GET /api/chat/:conversationId/messages - Get messages for a conversation
router.get('/:conversationId/messages', protect, async (req, res) => {
  try {
    const userId = req.sellerId;
    const conversation = await Conversation.findById(req.params.conversationId);

    if (!conversation) {
      return res.status(404).json({ message: 'Conversation not found' });
    }

    // Ensure user is a participant
    if (!conversation.participants.map(p => p.toString()).includes(userId)) {
      return res.status(403).json({ message: 'Not authorized to view this conversation' });
    }

    const messages = await Message.find({ conversationId: req.params.conversationId })
      .sort({ createdAt: 1 });

    res.json(messages);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// POST /api/chat/:conversationId/messages - Send a message
router.post('/:conversationId/messages', protect, async (req, res) => {
  try {
    const userId = req.sellerId;
    const { text } = req.body;

    if (!text || text.trim() === '') {
      return res.status(400).json({ message: 'Message cannot be empty' });
    }

    const conversation = await Conversation.findById(req.params.conversationId);
    if (!conversation) {
      return res.status(404).json({ message: 'Conversation not found' });
    }

    if (!conversation.participants.map(p => p.toString()).includes(userId)) {
      return res.status(403).json({ message: 'Not authorized' });
    }

    const message = await Message.create({
      conversationId: req.params.conversationId,
      senderId: userId,
      text: text.trim(),
    });

    // Update conversation's last message and timestamp
    conversation.lastMessage = text.trim();
    conversation.updatedAt = new Date();
    await conversation.save();

    res.status(201).json(message);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// GET /api/chat/:conversationId/info - Get conversation info (other user + item)
router.get('/:conversationId/info', protect, async (req, res) => {
  try {
    const userId = req.sellerId;
    const conversation = await Conversation.findById(req.params.conversationId);

    if (!conversation) {
      return res.status(404).json({ message: 'Conversation not found' });
    }

    if (!conversation.participants.map(p => p.toString()).includes(userId)) {
      return res.status(403).json({ message: 'Not authorized' });
    }

    const otherUserId = conversation.participants.find(p => p.toString() !== userId);
    const otherUser = await User.findById(otherUserId).select('name email');
    const item = await Item.findById(conversation.itemId).select('title imageUrl price');

    res.json({
      _id: conversation._id,
      otherUser: otherUser ? { _id: otherUser._id, name: otherUser.name, email: otherUser.email } : null,
      item: item ? { _id: item._id, title: item.title, imageUrl: item.imageUrl, price: item.price } : null,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;

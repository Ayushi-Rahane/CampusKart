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
    const buyerId = req.sellerId; // current logged-in user

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

    const result = [];
    for (const conv of conversations) {
      const otherUserId = conv.participants.find(p => p.toString() !== userId);
      const otherUser = await User.findById(otherUserId).select('name email');
      const item = await Item.findById(conv.itemId).select('title imageUrl price');

      // Count unread messages (messages not sent by me that are not 'read')
      const unreadCount = await Message.countDocuments({
        conversationId: conv._id,
        senderId: { $ne: userId },
        status: { $ne: 'read' },
      });

      result.push({
        _id: conv._id,
        otherUser: otherUser ? { _id: otherUser._id, name: otherUser.name, email: otherUser.email } : null,
        item: item ? { _id: item._id, title: item.title, imageUrl: item.imageUrl, price: item.price } : null,
        lastMessage: conv.lastMessage,
        updatedAt: conv.updatedAt,
        unreadCount: unreadCount,
      });
    }

    res.json(result);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// GET /api/chat/unread-total - Get total unread message count for the user
router.get('/unread-total', protect, async (req, res) => {
  try {
    const userId = req.sellerId;
    const conversations = await Conversation.find({ participants: userId });
    const convIds = conversations.map(c => c._id);

    const unreadCount = await Message.countDocuments({
      conversationId: { $in: convIds },
      senderId: { $ne: userId },
      status: { $ne: 'read' },
    });

    res.json({ unreadCount });
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

    if (!conversation.participants.map(p => p.toString()).includes(userId)) {
      return res.status(403).json({ message: 'Not authorized to view this conversation' });
    }

    const messages = await Message.find({ conversationId: req.params.conversationId })
      .sort({ createdAt: 1 });

    // Mark messages from other user as 'delivered' if they were 'sent'
    await Message.updateMany(
      {
        conversationId: req.params.conversationId,
        senderId: { $ne: userId },
        status: 'sent',
      },
      { $set: { status: 'delivered' } }
    );

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
      status: 'sent',
    });

    conversation.lastMessage = text.trim();
    conversation.updatedAt = new Date();
    await conversation.save();

    res.status(201).json(message);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// PATCH /api/chat/:conversationId/read - Mark all messages from other user as read
router.patch('/:conversationId/read', protect, async (req, res) => {
  try {
    const userId = req.sellerId;
    const conversation = await Conversation.findById(req.params.conversationId);

    if (!conversation) {
      return res.status(404).json({ message: 'Conversation not found' });
    }

    if (!conversation.participants.map(p => p.toString()).includes(userId)) {
      return res.status(403).json({ message: 'Not authorized' });
    }

    // Mark all messages from the OTHER user as 'read'
    const result = await Message.updateMany(
      {
        conversationId: req.params.conversationId,
        senderId: { $ne: userId },
        status: { $ne: 'read' },
      },
      { $set: { status: 'read' } }
    );

    res.json({ marked: result.modifiedCount });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// GET /api/chat/:conversationId/info - Get conversation info
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

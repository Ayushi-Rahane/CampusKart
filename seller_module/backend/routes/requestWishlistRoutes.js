const express = require('express');
const router = express.Router();
const RequestWishlist = require('../models/RequestWishlist');
const Item = require('../models/Item');
const { protect } = require('../middleware/auth');

// Helper: extract keywords from a string
function extractKeywords(text) {
  const stopWords = ['a', 'an', 'the', 'for', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'of', 'i', 'my', 'me', 'we', 'want', 'need', 'looking', 'buy'];
  return text
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, '')
    .split(/\s+/)
    .filter(w => w.length > 1 && !stopWords.includes(w));
}

// POST /api/request-wishlist - Add a new request
router.post('/', protect, async (req, res) => {
  try {
    const { itemName, category, description } = req.body;
    if (!itemName || !itemName.trim()) {
      return res.status(400).json({ message: 'Item name is required' });
    }

    const keywords = extractKeywords(itemName);

    const entry = await RequestWishlist.create({
      userId: req.sellerId,
      itemName: itemName.trim(),
      category: category || '',
      description: description || '',
      keywords,
    });

    // Check if a matching item already exists
    const matchingItem = await _findMatchingItem(keywords);
    if (matchingItem) {
      entry.matched = true;
      entry.matchedItemId = matchingItem._id;
      await entry.save();

      // Create a notification
      const Notification = require('../models/Notification');
      await Notification.create({
        userId: req.sellerId,
        type: 'item_available',
        title: 'Item Available!',
        message: `"${matchingItem.title}" matching your request "${itemName}" is now available!`,
        itemId: matchingItem._id,
        requestWishlistId: entry._id,
      });
    }

    res.status(201).json(entry);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// GET /api/request-wishlist - Get user's requested items
router.get('/', protect, async (req, res) => {
  try {
    const entries = await RequestWishlist.find({ userId: req.sellerId })
      .populate('matchedItemId')
      .sort({ createdAt: -1 });

    for (const entry of entries) {
      // Self-heal: fix stale keywords that included category/description
      const correctKeywords = extractKeywords(entry.itemName);
      if (JSON.stringify(entry.keywords.sort()) !== JSON.stringify(correctKeywords.sort())) {
        entry.keywords = correctKeywords;
        await entry.save();
      }

      // Self-heal: if matched but item was deleted, reset to unmatched
      if (entry.matched && !entry.matchedItemId) {
        entry.matched = false;
        entry.matchedItemId = null;
        await entry.save();
      }
    }

    res.json(entries);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// DELETE /api/request-wishlist/:id - Remove a request
router.delete('/:id', protect, async (req, res) => {
  try {
    await RequestWishlist.findOneAndDelete({ _id: req.params.id, userId: req.sellerId });
    res.json({ message: 'Request removed' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Helper function to find a matching available item
async function _findMatchingItem(keywords) {
  if (!keywords || keywords.length === 0) return null;

  const items = await Item.find({ status: 'available' }).sort({ createdAt: -1 });

  for (const item of items) {
    const itemTitleWords = extractKeywords(item.title);
    if (itemTitleWords.length === 0) continue;

    // Check: do all words of the shorter set appear in the longer set?
    const shorter = keywords.length <= itemTitleWords.length ? keywords : itemTitleWords;
    const longer = keywords.length > itemTitleWords.length ? keywords : itemTitleWords;

    if (shorter.every(w => longer.includes(w))) {
      return item;
    }
  }

  return null;
}

// Exported helper for use in itemRoutes when a new item is posted
router.matchNewItemAgainstRequests = async function(newItem) {
  try {
    const Notification = require('../models/Notification');
    const titleWords = extractKeywords(newItem.title);

    console.log('Matching new item:', newItem.title, '-> keywords:', titleWords);

    if (titleWords.length === 0) return;

    // Find all unmatched requests
    const unmatchedRequests = await RequestWishlist.find({ matched: false });
    console.log('Unmatched requests found:', unmatchedRequests.length);

    for (const request of unmatchedRequests) {
      const reqKeywords = request.keywords;
      if (!reqKeywords || reqKeywords.length === 0) continue;

      // Check: do all words of the shorter set appear in the longer set?
      const shorter = reqKeywords.length <= titleWords.length ? reqKeywords : titleWords;
      const longer = reqKeywords.length > titleWords.length ? reqKeywords : titleWords;

      const overlap = shorter.every(w => longer.includes(w));
      console.log(`  Request "${request.itemName}" [${reqKeywords}] vs Item [${titleWords}] -> match: ${overlap}`);

      if (overlap) {
        request.matched = true;
        request.matchedItemId = newItem._id;
        await request.save();

        // Create notification for the requesting buyer
        await Notification.create({
          userId: request.userId,
          type: 'item_available',
          title: 'Item Available!',
          message: `"${newItem.title}" matching your request "${request.itemName}" is now available for ₹${newItem.price}!`,
          itemId: newItem._id,
          requestWishlistId: request._id,
        });
      }
    }
  } catch (error) {
    console.error('Error matching new item against requests:', error);
  }
};

module.exports = router;

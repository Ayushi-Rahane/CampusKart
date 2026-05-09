const mongoose = require('mongoose');
const User = require('./models/User');
const Item = require('./models/Item');
require('dotenv').config();

const removeSeedData = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/campuskart');
    console.log('MongoDB connected for removing seed data');
    
    const emails = [
      'alice@campuskart.com', 'bob@campuskart.com', 'charlie@campuskart.com',
      'rahul@campuskart.com', 'priya@campuskart.com', 'amit@campuskart.com'
    ];
    
    const users = await User.find({ email: { $in: emails } });
    const userIds = users.map(u => u._id);
    
    const itemsResult = await Item.deleteMany({ sellerId: { $in: userIds } });
    console.log(`Deleted ${itemsResult.deletedCount} items.`);
    
    const usersResult = await User.deleteMany({ _id: { $in: userIds } });
    console.log(`Deleted ${usersResult.deletedCount} users.`);
    
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
};

removeSeedData();

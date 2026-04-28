const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const User = require('./models/User');
const Item = require('./models/Item');

const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/campuskart');
    console.log('MongoDB connected for seeding');
  } catch (error) {
    console.error('Error connecting to MongoDB:', error);
    process.exit(1);
  }
};

const seedDatabase = async () => {
  await connectDB();

  console.log('Clearing old specific mock data if it exists...');
  await User.deleteMany({ email: { $in: [
    'alice@campuskart.com', 'bob@campuskart.com', 'charlie@campuskart.com',
    'rahul@campuskart.com', 'priya@campuskart.com', 'amit@campuskart.com'
  ] } });
  
  console.log('Creating users...');
  const salt = await bcrypt.genSalt(10);
  const hashedPassword = await bcrypt.hash('password123', salt);

  const rahul = await User.create({
    name: 'Rahul Sharma',
    email: 'rahul@campuskart.com',
    password: hashedPassword,
    phone: '9876543210'
  });

  const priya = await User.create({
    name: 'Priya Patel',
    email: 'priya@campuskart.com',
    password: hashedPassword,
    phone: '9123456789'
  });

  const amit = await User.create({
    name: 'Amit Singh',
    email: 'amit@campuskart.com',
    password: hashedPassword,
    phone: '9988776655'
  });

  console.log('Creating items...');
  const item1 = await Item.create({
    sellerId: rahul._id,
    title: 'Engineering Mathematics (B.S. Grewal)',
    description: 'Barely used, 44th edition. Essential for first year.',
    price: 450,
    category: 'Books',
    location: 'Boys Hostel 1',
    imageUrl: 'https://images.unsplash.com/photo-1544947950-fa07a98d237f',
    status: 'sold',
    buyerId: priya._id
  });

  const item2 = await Item.create({
    sellerId: priya._id,
    title: 'Mini Drafter & ED Kit',
    description: 'Omega drafter, scale, and drawing clips included.',
    price: 250,
    category: 'Others',
    location: 'Girls Hostel 3',
    imageUrl: 'https://images.unsplash.com/photo-1587145820266-a5951ee6f620',
    status: 'sold',
    buyerId: amit._id
  });

  const item3 = await Item.create({
    sellerId: amit._id,
    title: 'Lab Coat and Safety Goggles',
    description: 'Size Medium. Used only for one semester in Chemistry lab.',
    price: 300,
    category: 'Others',
    location: 'Boys Hostel 2',
    imageUrl: 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15', // Placeholder
    status: 'sold',
    buyerId: rahul._id
  });

  // Available items
  await Item.create({
    sellerId: rahul._id,
    title: 'Used Hero Sprint Cycle',
    description: 'Good condition, perfect for getting to classes on time. Needs a little oiling.',
    price: 1500,
    category: 'Others',
    location: 'Boys Hostel 1',
    imageUrl: 'https://images.unsplash.com/photo-1485965120184-e220f721d03e',
    status: 'available'
  });

  await Item.create({
    sellerId: priya._id,
    title: 'Prestige Induction Cooktop',
    description: 'Perfect for Maggi at 2 AM. Works perfectly.',
    price: 1200,
    category: 'Electronics',
    location: 'Girls Hostel 3',
    imageUrl: 'https://images.unsplash.com/photo-1584568694244-14fbdf83bd30',
    status: 'available'
  });

  await Item.create({
    sellerId: amit._id,
    title: 'Yamaha Acoustic Guitar',
    description: 'Great for cultural fest practice. Comes with a bag.',
    price: 3500,
    category: 'Others',
    location: 'Boys Hostel 2',
    imageUrl: 'https://images.unsplash.com/photo-1510915361894-faa8b2d5de8f',
    status: 'available'
  });

  console.log('Adding ratings...');
  rahul.ratings.push({
    buyerId: priya._id,
    itemId: item1._id,
    rating: 5,
    feedback: 'Book was in great condition, very helpful for semester exams.',
    imageUrl: 'https://images.unsplash.com/photo-1544947950-fa07a98d237f'
  });
  await rahul.save();

  priya.ratings.push({
    buyerId: amit._id,
    itemId: item2._id,
    rating: 4,
    feedback: 'Drafter works perfectly, but the carrying case is slightly damaged.',
    imageUrl: ''
  });
  await priya.save();

  amit.ratings.push({
    buyerId: rahul._id,
    itemId: item3._id,
    rating: 5,
    feedback: 'Lab coat fits well and goggles are scratch-free. Thanks bhai!',
    imageUrl: ''
  });
  await amit.save();

  console.log('Database seeded successfully!');
  process.exit();
};

seedDatabase();

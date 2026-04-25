const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
dotenv.config();

// Routes
const itemRoutes = require('./routes/itemRoutes');
const authRoutes = require('./routes/authRoutes');
const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// API Routes
app.use('/api/items', itemRoutes);
app.use('/api/auth', authRoutes);

// Root endpoint
app.get('/', (req, res) => {
  res.send('CampusCart Seller Module API is running...');
});

// Global error handler to always return JSON instead of HTML
app.use((err, req, res, next) => {
  console.error("Global Error:", err);
  res.status(500).json({ message: err.message || 'Internal Server Error' });
});

const PORT = process.env.PORT || 5000;

// Database Connection
mongoose.connect(process.env.MONGO_URI)
  .then(() => {
    console.log('✅ MongoDB Connected Successfully');
    app.listen(PORT, () => console.log(`🚀 Seller Backend running on port ${PORT}`));
  })
  .catch(err => {
    console.error('❌ MongoDB Connection Failed:', err.message);
  });

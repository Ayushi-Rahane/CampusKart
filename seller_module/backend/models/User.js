const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  phone: { type: String, default: '' },
  address: { type: String, default: '' },
  ratings: [{
    buyerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    itemId: { type: mongoose.Schema.Types.ObjectId, ref: 'Item' },
    rating: { type: Number, required: true, min: 1, max: 5 },
    feedback: { type: String, default: '' },
    imageUrl: { type: String, default: '' },
    createdAt: { type: Date, default: Date.now }
  }],
}, { timestamps: true });

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) next();
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});

module.exports = mongoose.model('User', userSchema);

const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const { sendOtpEmail } = require('../config/mailer');

const EMAIL_REGEX = /^[a-z]+\.[a-z]+@cumminscollege\.in$/;

function generateOtp() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// POST /api/auth/register
router.post('/register', async (req, res) => {
  try {
    const { name, email, password } = req.body;
    if (!name || !email || !password) {
      return res.status(400).json({ message: 'All fields are required' });
    }

    const normalizedEmail = email.trim().toLowerCase();

    // Backend email format validation (source of truth)
    if (!EMAIL_REGEX.test(normalizedEmail)) {
      return res.status(400).json({ message: 'Only firstname.lastname@cumminscollege.in emails are allowed' });
    }

    if (password.length < 6) {
      return res.status(400).json({ message: 'Password must be at least 6 characters' });
    }

    let user = await User.findOne({ email: normalizedEmail });

    // If verified user already exists, block
    if (user && user.emailVerified) {
      return res.status(400).json({ message: 'User already exists. Please login.' });
    }

    // If unverified user exists, update their info (re-registration attempt)
    if (user && !user.emailVerified) {
      user.name = name;
      user.password = password; // pre-save hook will hash
      await user.save();
    } else {
      user = await User.create({ name, email: normalizedEmail, password });
    }

    // Generate OTP
    const otp = generateOtp();
    user.otp = await bcrypt.hash(otp, 10);
    user.otpExpiry = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
    user.otpAttempts = 0;
    user.lastOtpSent = new Date();
    await user.save();

    // Send OTP email
    try {
      await sendOtpEmail(normalizedEmail, otp);
    } catch (mailError) {
      console.error('Failed to send OTP email:', mailError.message);
      return res.status(500).json({ message: 'Failed to send verification email. Please try again.' });
    }

    console.log(`OTP sent to ${normalizedEmail}`);
    res.status(201).json({ message: 'OTP sent to your college email. Please verify.' });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ message: error.message });
  }
});

// POST /api/auth/verify-otp
router.post('/verify-otp', async (req, res) => {
  try {
    const { email, otp } = req.body;
    if (!email || !otp) {
      return res.status(400).json({ message: 'Email and OTP are required' });
    }

    const user = await User.findOne({ email: email.trim().toLowerCase() });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (user.emailVerified) {
      return res.status(400).json({ message: 'Email already verified. Please login.' });
    }

    // Brute-force protection
    if (user.otpAttempts >= 5) {
      return res.status(429).json({ message: 'Too many incorrect attempts. Please request a new OTP.' });
    }

    // Expiry check
    if (!user.otpExpiry || user.otpExpiry < new Date()) {
      return res.status(400).json({ message: 'OTP has expired. Please request a new one.' });
    }

    // Compare OTP
    const isMatch = await bcrypt.compare(otp, user.otp);
    if (!isMatch) {
      user.otpAttempts += 1;
      await user.save();
      const remaining = 5 - user.otpAttempts;
      return res.status(400).json({ message: `Incorrect OTP. ${remaining} attempt${remaining !== 1 ? 's' : ''} remaining.` });
    }

    // Success — mark verified
    user.emailVerified = true;
    user.otp = null;
    user.otpExpiry = null;
    user.otpAttempts = 0;
    await user.save();

    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '30d' });
    console.log(`Email verified: ${user.email}`);
    res.json({ token, user: { id: user._id, name: user.name, email: user.email } });
  } catch (error) {
    console.error('Verify OTP error:', error);
    res.status(500).json({ message: error.message });
  }
});

// POST /api/auth/resend-otp
router.post('/resend-otp', async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ message: 'Email is required' });
    }

    const user = await User.findOne({ email: email.trim().toLowerCase() });
    if (!user) {
      return res.status(404).json({ message: 'User not found. Please register first.' });
    }

    if (user.emailVerified) {
      return res.status(400).json({ message: 'Email already verified. Please login.' });
    }

    // Rate limit: 1 OTP per 60 seconds
    if (user.lastOtpSent && (Date.now() - user.lastOtpSent.getTime()) < 60000) {
      const waitSeconds = Math.ceil((60000 - (Date.now() - user.lastOtpSent.getTime())) / 1000);
      return res.status(429).json({ message: `Please wait ${waitSeconds} seconds before requesting a new OTP.` });
    }

    const otp = generateOtp();
    user.otp = await bcrypt.hash(otp, 10);
    user.otpExpiry = new Date(Date.now() + 10 * 60 * 1000);
    user.otpAttempts = 0;
    user.lastOtpSent = new Date();
    await user.save();

    try {
      await sendOtpEmail(user.email, otp);
    } catch (mailError) {
      console.error('Failed to resend OTP email:', mailError.message);
      return res.status(500).json({ message: 'Failed to send email. Please try again.' });
    }

    console.log(`OTP resent to ${user.email}`);
    res.json({ message: 'New OTP sent to your email.' });
  } catch (error) {
    console.error('Resend OTP error:', error);
    res.status(500).json({ message: error.message });
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const normalizedEmail = email.trim().toLowerCase();
    const user = await User.findOne({ email: normalizedEmail });

    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    // Block unverified users
    if (!user.emailVerified) {
      return res.status(403).json({ message: 'Email not verified. Please check your inbox for the OTP.' });
    }

    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '30d' });
    res.json({ token, user: { id: user._id, name: user.name, email: user.email } });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;

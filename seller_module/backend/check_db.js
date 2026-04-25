const mongoose = require('mongoose');
const Item = require('./models/Item');
const dotenv = require('dotenv');

dotenv.config();

mongoose.connect(process.env.MONGO_URI)
  .then(async () => {
    const items = await Item.find().sort({ createdAt: -1 }).limit(5);
    console.log("Recent items:");
    console.log(JSON.stringify(items, null, 2));
    process.exit(0);
  })
  .catch(err => {
    console.error(err);
    process.exit(1);
  });

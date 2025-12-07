const express = require('express');
const os = require('os');

const app = express();
const PORT = 3000;

app.get('/', (req, res) => {
    res.json({
        app: 'Node.js API',
        message: 'Hello from Node.js!',
        endpoint: '/',
        host: os.hostname()
    });
});

app.get('/api/products', (req, res) => {
    res.json({
        products: [
            { id: 1, name: 'Laptop', price: 999 },
            { id: 2, name: 'Mouse', price: 29 },
            { id: 3, name: 'Keyboard', price: 79 }
        ]
    });
});

app.get('/health', (req, res) => {
    res.json({ status: 'healthy' });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Node.js app listening on port ${PORT}`);
});

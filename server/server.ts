import express from 'express';
import cors from 'cors';
import path from 'path';

const app = express();

app.use(cors({
    origin: '*',
    methods: ['GET', 'OPTIONS'],
    optionsSuccessStatus: 204,
}));

// 重要：定位到项目根的 assets/data
const staticDir = path.resolve(__dirname, '../assets/data');
console.log('serving static from:', staticDir);

app.use(express.static(staticDir));

// 可选：健康检查
app.get('/ping', (_req, res) => res.send('pong'));

app.listen(5173, '0.0.0.0', () => {
    console.log('dev server on http://127.0.0.1:5173');
});
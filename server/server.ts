// server.ts
import express from 'express';
import cors from 'cors';
import path from 'path';
import { Writable } from 'node:stream';

const app = express();

app.use(cors({ origin: '*', methods: ['GET', 'OPTIONS'], optionsSuccessStatus: 204 }));

const staticDir = path.resolve(__dirname, '../assets/data');
console.log('serving static from:', staticDir);
app.use(express.static(staticDir));

app.get('/proxy', async (req, res) => {
    const url = req.query.url as string;
    if (!url) return res.status(400).send('url required');

    try {
        const r = await fetch(url, {
            headers: { 'User-Agent': 'Mozilla/5.0', Accept: 'image/*' },
        });

        res.setHeader('Access-Control-Allow-Origin', '*');
        res.setHeader('Cache-Control', 'public, max-age=60');
        res.setHeader('Content-Type', r.headers.get('content-type') ?? 'application/octet-stream');
        res.status(r.status);

        if (!r.body) return res.end();

        // ⭐️ 关键：Web ReadableStream -> Web WritableStream(res)
        await r.body.pipeTo(Writable.toWeb(res));
    } catch (e: any) {
        console.error('proxy error:', e);
        res.status(502).send(String(e));
    }
});

app.get('/ping', (_req, res) => res.send('pong'));
app.listen(5173, '0.0.0.0', () => console.log('dev server on http://127.0.0.1:5173'));
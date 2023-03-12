import express from 'express';
import http from 'http';
import path from 'path';

const SERVER_PORT = 3000;
export function health() {
    const router = new express.Router();

    router.get('/', (req, res) => {
        res.status(200);
        res.json({status: 'OK'});
    });

    return router;
};

export function getImage() {
    const router = new express.Router();
    router.get('/:name', (req, res) => {
        const name = req.params.name;
        let filename;
        switch(name) {
            case 'eks':
                filename = 'eks';
                break;
            case 'gke':
                filename = 'gke';
                break;
            default:
                filename = 'fargate';
        }
        const filePath = `resource/${filename}.html`;
        res.status(200);
        res.sendFile(filePath, {root: __dirname });
    });

    return router;
};

export function getDefaultImage() {
    const router = new express.Router();

    router.get('/', (req, res) => {
            res.status(200);
        res.sendFile('resource/fargate.html', {root: __dirname });
    });

    return router;
};

export function server() {
    console.log(`Server is listeninig on port ${SERVER_PORT}`);
    const routes = {
        '/health': health(),
        '/cloud': getImage(),
        '/': getDefaultImage(),
    };

  return createServer(routes);
}

export function createServer(routes) {

    const app = express();
    Object.keys(routes).forEach(routeName => {
        app.use(routeName, routes[routeName]);
    });
    app.use(express.static('resource'))
    const server = http.createServer(app);
    server.listen(SERVER_PORT);

    return server;
}

const __dirname = path.resolve();
server();

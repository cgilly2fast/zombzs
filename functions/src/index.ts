import * as crypto from 'crypto'
import { onRequest } from 'firebase-functions/v2/https'
import { log } from 'firebase-functions/logger'
import { db } from './credentials'

const SECRET_KEY = '42069letsfuckingo'

interface Score {
    name: string
    lvl: number
    score: number
}

interface Payload extends Score {
    hash: string
}

function generateHash(payload: Score): string {
    const { name, lvl, score } = payload
    const dataToHash = `${name}${lvl.toString()}${score.toString()}${SECRET_KEY}`

    const utf8Data = Buffer.from(dataToHash, 'utf8')

    const hash = crypto.createHash('sha256').update(utf8Data).digest('hex')
    return hash
}

function verifyHash(payload: Payload) {
    const { hash, ...dataToHash } = payload
    const calculatedHash = generateHash(dataToHash)
    log('calcHash', calculatedHash)
    return hash === calculatedHash
}

export const getLeaderBoard = onRequest({ cors: true }, async (request, response) => {
    const snapshot = await db.collection('scores').orderBy('score', 'desc').get()
    let data: Score[] = []
    snapshot.forEach((doc) => {
        data.push(doc.data() as Score)
    })
    response.send({ data })
})

export const postScore = onRequest({ cors: true }, async (request, response) => {
    const payload: Payload = request.body
    log(request.body)
    if (payload.name === '' || payload.lvl === 0) {
        response.sendStatus(200)
        return
    }
    if (verifyHash(payload)) {
        try {
            await db.collection('scores').add(payload)
            response.sendStatus(200)
        } catch (error) {
            log(error)
            response.sendStatus(401)
        }
    } else {
        response.sendStatus(403)
    }
})

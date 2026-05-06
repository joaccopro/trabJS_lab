import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";

const s3 = new S3Client({});
const BUCKET_NAME = process.env.BUCKET_NAME;

export const handler = async (event) => {
    try {
        const body = JSON.parse(event.body);
        const imageBuffer = Buffer.from(body.image, 'base64');
        const fileName = `raw/${Date.now()}.jpg`;

        await s3.send(new PutObjectCommand({
            Bucket: BUCKET_NAME,
            Key: fileName,
            Body: imageBuffer,
            ContentType: "image/jpeg"
        }));

        return {
            statusCode: 200,
            body: JSON.stringify({ message: "Imagen subida con éxito", key: fileName })
        };
    } catch (error) {
        console.error(error);
        return { statusCode: 500, body: JSON.stringify({ error: "Error al subir imagen" }) };
    }
};
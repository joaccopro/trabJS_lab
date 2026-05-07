import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";

const s3 = new S3Client({});
const BUCKET_NAME = process.env.BUCKET_NAME;

export const handler = async (event) => {
    try {
        console.log("Evento recibido:", JSON.stringify(event));

        let imageBuffer;
        if (event.isBase64Encoded) {
            imageBuffer = Buffer.from(event.body, 'base64');
        } else {
            try {
                const body = JSON.parse(event.body);
                imageBuffer = Buffer.from(body.image, 'base64');
            } catch (e) {
                imageBuffer = Buffer.from(event.body);
            }
        }

        const fileName = `uploads/${Date.now()}.jpg`;

        await s3.send(new PutObjectCommand({
            Bucket: BUCKET_NAME,
            Key: fileName,
            Body: imageBuffer,
            ContentType: "image/jpeg"
        }));

        return {
            statusCode: 200,
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ 
                message: "¡Imagen subida con éxito!", 
                key: fileName,
                bucket: BUCKET_NAME 
            })
        };
    } catch (error) {
        console.error("DETALLE DEL ERROR:", error);
        return { 
            statusCode: 500, 
            body: JSON.stringify({ 
                error: "Error al subir imagen", 
                details: error.message 
            }) 
        };
    }
};
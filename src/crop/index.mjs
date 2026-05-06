export const handler = async (event) => {
    for (const record of event.Records) {
        const body = JSON.parse(record.body);
        console.log("Procesando imagen del evento:", body);
        console.log("Simulando recorte de imagen con 512MB de RAM...");
        await new Promise(resolve => setTimeout(resolve, 1000));
    }
    
    return { status: "Procesamiento completado" };
};

class PRTMaterial extends Material {

    constructor(color, specular, light, vertexShader, fragmentShader) {
        let lightIntensity = light.mat.GetIntensity();
        super({
            // uniform variables
            'uSampler': { type: 'texture', value: color },
            'uKs': { type: '3fv', value: specular },
            'uLightRadiance': { type: '3fv', value: lightIntensity },     
            'uPrecomputeR' : {type: 'updatedInRealTime', value: null},
            'uPrecomputeG' : {type: 'updatedInRealTime', value: null},
            'uPrecomputeB' : {type: 'updatedInRealTime', value: null},
        }, ['aPrecomputeLT'], vertexShader, fragmentShader, null);
    }
}

async function buildPRTMaterial(color, specular, light, vertexPath, fragmentPath) 
{
    let vertexShader = await getShaderString(vertexPath);
    let fragmentShader = await getShaderString(fragmentPath);

    return new PRTMaterial(color, specular, light, vertexShader, fragmentShader);
}
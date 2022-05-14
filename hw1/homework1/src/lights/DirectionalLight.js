class DirectionalLight {

    constructor(lightIntensity, lightColor, lightPos, focalPoint, lightUp, hasShadowMap, gl) {
        this.mesh = Mesh.cube(setTransform(0, 0, 0, 0.1, 0.1, 0.1, 0));
        this.mat = new EmissiveMaterial(lightIntensity, lightColor);
        this.lightPos = lightPos;
        this.focalPoint = focalPoint;
        this.lightUp = lightUp

        this.hasShadowMap = hasShadowMap;
        this.fbo = new FBO(gl);
        if (!this.fbo) {
            console.log("无法设置帧缓冲区对象");
            return;
        }
    }

    CalcLightMVP(translate, scale) {
        let lightMVP = mat4.create();
        let modelMatrix = mat4.create();
        let viewMatrix = mat4.create();
        let projectionMatrix = mat4.create();

        //console.log(translate);
        //console.log(scale);
        // Model transform
        //modelMatrix.setTranslate(this.lightPos);
        mat4.identity(modelMatrix)
        mat4.translate(modelMatrix, modelMatrix, translate);
        mat4.scale(modelMatrix, modelMatrix, scale);
       
        // View transform
        // Look at , we need lightPos, focalPoint and lightUp
        mat4.lookAt(viewMatrix, this.lightPos, this.focalPoint, this.lightUp);
            

        // Projection transform
        // mat4.ortho(-10.0f, 10.0f, -10.0f, 10.0f, near_plane, far_plane);
        var lightDepth = 1600.0;
        var lightBoxHeight = 200.0;
        var lightBoxWidth = 200.0;

        mat4.ortho(projectionMatrix, -lightBoxWidth, lightBoxWidth, -lightBoxHeight, lightBoxHeight, 0, lightDepth);

        mat4.multiply(lightMVP, projectionMatrix, viewMatrix);
        mat4.multiply(lightMVP, lightMVP, modelMatrix);

        return lightMVP;
    }
}

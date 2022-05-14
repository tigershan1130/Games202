class WebGLRenderer {
    meshes = [];
    shadowMeshes = [];
    lights = [];
    totalTime = 0;
    

    constructor(gl, camera) {
        this.gl = gl;
        this.camera = camera;
    }

    addLight(light) {
        this.lights.push({
            entity: light,
            meshRender: new MeshRender(this.gl, light.mesh, light.mat)
        });
    }
    addMeshRender(mesh) 
    { this.meshes.push(mesh); 
    }
    addShadowMeshRender(mesh) 
    { 
        //console.assert("Added new mesh");
        this.shadowMeshes.push(mesh); 
    }

    render(GUIParams) {

        const gl = this.gl;

        gl.enable(gl.DEPTH_TEST); // Enable depth testing
        gl.depthFunc(gl.LEQUAL); // Near things obscure far things

        console.assert(this.lights.length != 0, "No light");
        console.assert(this.lights.length == 1, "Multiple lights");

        // added for rotating light.
        var x = Math.cos(this.totalTime) * 50;
        var z = Math.sin(this.totalTime) * 50;

        //this.lights[0].meshRender.mesh.transform.translate = this.lights[0].entity.lightPos;
        this.lights[0].entity.lightPos = [x, 80, z];

        for (let l = 0; l < this.lights.length; l++) {
            // TODO: Support all kinds of transform            
            this.lights[l].meshRender.mesh.transform.translate = this.lights[l].entity.lightPos;  
                      
            this.lights[l].meshRender.draw(this.camera);




            // Shadow pass
            if (this.lights[l].entity.hasShadowMap == true) {
                
                // clear out our shadow texture depth
                this.gl.bindFramebuffer(this.gl.FRAMEBUFFER, this.lights[l].entity.fbo); 
                gl.clear(gl.DEPTH_BUFFER_BIT | gl.COLOR_BUFFER_BIT);
                
                for (let i = 0; i < this.shadowMeshes.length; i++) {
                    
                    this.gl.useProgram(this.shadowMeshes[i].shader.program.glShaderProgram);
                    this.gl.uniform3fv(this.shadowMeshes[i].shader.program.uniforms.uLightPos, this.lights[l].entity.lightPos);
                    var newLightMVP = this.lights[l].entity.CalcLightMVP(this.shadowMeshes[i].mesh.transform.translate, this.shadowMeshes[i].mesh.transform.scale); 
                    this.shadowMeshes[i].material.updateLightMvp(newLightMVP);
                    this.shadowMeshes[i].draw(this.camera);

                }
            }

            // Camera pass
            for (let i = 0; i < this.meshes.length; i++) {

                this.gl.useProgram(this.meshes[i].shader.program.glShaderProgram);
                var newLightMVP = this.lights[l].entity.CalcLightMVP(this.meshes[i].mesh.transform.translate, this.meshes[i].mesh.transform.scale); 
                this.meshes[i].material.updateLightMvp(newLightMVP);
                this.gl.uniform3fv(this.meshes[i].shader.program.uniforms.uLightPos, this.lights[l].entity.lightPos);
                this.meshes[i].draw(this.camera);
            }
        }
    }
}
local ShaderCode={
	mask= love.graphics.newShader([[
	   vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
	      if (Texel(texture, texture_coords).rgb == vec3(0.0)) {
	         // a discarded pixel wont be applied as the stencil.
	         discard;
	      }
	      return vec4(1.0);
	   }
	]])
	
}
return ShaderCode
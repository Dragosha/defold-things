varying mediump vec2 var_texcoord0;
uniform lowp sampler2D tex0;

float rgba_to_float(vec4 rgba)
{
    return dot(rgba, vec4(1.0, 1.0/255.0, 1.0/65025.0, 1.0/16581375.0));
}

void main()
{
    vec4 color = texture2D(tex0, var_texcoord0.xy);
    gl_FragColor = vec4(vec3(rgba_to_float(color)),1.0);
}


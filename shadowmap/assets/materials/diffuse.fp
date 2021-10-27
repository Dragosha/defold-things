varying mediump vec4 var_position;
varying mediump vec4 var_position_world;
varying mediump vec3 var_normal;
varying mediump vec2 var_texcoord0;
varying mediump vec4 var_texcoord0_shadow;
varying mediump vec4 var_light;
varying mediump vec4 var_light2;

uniform lowp vec4 ambient;
uniform lowp vec4 color1;
uniform lowp vec4 color2;
uniform lowp vec4 fog_color;

uniform lowp sampler2D tex0;
uniform lowp sampler2D tex_depth;

uniform mediump vec4 mtx_light_mvp0;
uniform mediump vec4 mtx_light_mvp1;
uniform mediump vec4 mtx_light_mvp2;
uniform mediump vec4 mtx_light_mvp3;

vec2 rand(vec2 co)
{
    return vec2(fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453),
    fract(sin(dot(co.yx ,vec2(12.9898,78.233))) * 43758.5453)) * 0.00047;
}

float rgba_to_float(vec4 rgba)
{
    return dot(rgba, vec4(1.0, 1.0/255.0, 1.0/65025.0, 1.0/16581375.0));
}

float shadow_calculation(vec4 depth_data)
{
    const float depth_bias = 0.001;
    // const float depth_bias = 0.00002; // for perspective camera
    
    float shadow = 0.0;
    float texel_size = 1.0 / 4096.0;//textureSize(tex_depth, 0);
    for (int x = -1; x <= 1; ++x)
    {
        for (int y = -1; y <= 1; ++y)
        {
            vec2 uv = depth_data.st + vec2(x,y) * texel_size;
            vec4 rgba = texture2D(tex_depth, uv + rand(uv));
            float depth = rgba_to_float(rgba);
            shadow += depth_data.z - depth_bias > depth ? 0.5 : 0.0;
        }
    }
    shadow /= 9.0;

    return shadow;
}

vec3 point_light(vec3 light_color, float power, vec3 light_position, vec3 position, vec3 vnormal)
{
    vec3 dist = light_position - position;
    vec3 direction = vec3(normalize(dist));
    float d = length(dist);
    power = 1.0 /(0.1 + power);
    vec3 diffuse = light_color * max(dot(vnormal, direction), 0.1) * (1.0/(1.0 + d*power + d*d*power*power));
    return diffuse;
}

void main()
{
    vec4 color = texture2D(tex0, var_texcoord0.xy);
    // Add shadow map
    vec4 depth_proj = var_texcoord0_shadow / var_texcoord0_shadow.w;
    float shadow = 1.0 - shadow_calculation(depth_proj.xyzw);
    vec3 shadow_color = vec3(shadow, shadow, clamp(shadow + 0.2, 0.0, 1.0));

    // Diffuse light calculations
    vec3 diff_light = point_light(color1.rgb, 500.0, var_light.xyz, var_position.xyz, var_normal);
    diff_light     += point_light(color2.rgb, 30.0, var_light2.xyz, var_position.xyz, var_normal);
    diff_light     += vec3(ambient.xyz);
    diff_light      = clamp(diff_light, 0.0, 1.2);
    vec3 frag_color  = color.rgb * diff_light * shadow_color;

    // Fog
    float fog_dist = abs(var_position.z);
    float fog_max = 50.0;
    float fog_min = 10.0;
    float fog_factor = clamp((fog_max - fog_dist) / (fog_max - fog_min) + fog_color.a, 0.0, 1.0 );
    frag_color = mix(fog_color.rgb, frag_color, fog_factor);

    // frag_color.r = clamp(frag_color.r, 0.1, 1.0);
    // frag_color.g = clamp(frag_color.g, 0.1, 1.0);
    // frag_color.b = clamp(frag_color.b, 0.2, 1.0);

    gl_FragColor = vec4(frag_color, color.a);
}


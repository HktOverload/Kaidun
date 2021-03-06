#version 330

#define PI 3.1415926538

#define UP vec3(0.0, 0.0, 1.0)

in vec3 vert;
in vec3 aux_surf_normal;

out vec3 vert_color;
out float illum;
flat out vec3 illum_frag_phong_oren_nayar_to_i;
out vec3 illum_frag_phong_oren_nayar_to_r;
flat out float illum_frag_phong_oren_nayar_coef_a;
flat out float illum_frag_phong_oren_nayar_coef_b;
flat out float illum_frag_phong_lighting_ambient;
flat out float illum_frag_phong_lighting_maxsc;
// See the comment about pseudo-Phong shading in the fragment shader
// I know this line is an oxymoron. Leave me alone.
flat out vec3 phong_surf_normal;
out float fog_visibility_frac;
out vec3 fog_component_rgb_partial;

uniform vec3 cam_ctr;
uniform float cam_yaw;
uniform float cam_pitch;
uniform float cam_roll;
uniform float cam_near;
uniform float cam_dist;

uniform float lighting_ambient;
uniform float lighting_maxsc;
uniform vec3 lighting_light_ctr;
uniform float lighting_light_brightness;

uniform float surf_albedo;
uniform float surf_roughness;

uniform vec3 fog_color;
uniform float fog_attenuation_coef;

mat3 camspace_rot() {
    float a = cam_yaw;
    float b = cam_pitch;
    float c = cam_roll;
    return mat3(
        /* 0 0 */ cos(b)*cos(c),
        /* 0 1 */ cos(b)*sin(c),
        /* 0 2 */ -sin(b),
        /* 1 0 */ (sin(a)*sin(b)*cos(c))-(cos(a)*sin(c)),
        /* 1 1 */ (sin(a)*sin(b)*sin(c))+(cos(a)*cos(c)),
        /* 1 2 */ sin(a)*cos(b),
        /* 2 0 */ (cos(a)*sin(b)*cos(c))+(sin(a)*sin(c)),
        /* 2 1 */ (cos(a)*sin(b)*sin(c))-(sin(a)*cos(c)),
        /* 2 2 */ cos(a)*cos(b)
    );
}

void camspace(inout vec3 v) {
    v -= cam_ctr;
    v *= camspace_rot();
}

float zbuffer_value(float z) {
    return sqrt(z - cam_near) / sqrt(cam_dist);
}

void set_illum(out float illum) {
    vec3 deltas = vert - lighting_light_ctr;
    float dist = length(deltas);
    illum = lighting_light_brightness / (dist * dist);
}

void update_illum_lambertian(inout float illum) {
    illum *= surf_albedo / PI;
    vec3 to_i = normalize(lighting_light_ctr - vert);
    illum *= abs(dot(to_i, aux_surf_normal));
}

float get_oren_nayar_coef_a() {
    float microfacet_var = surf_roughness * surf_roughness;
    float const_frac = microfacet_var / (microfacet_var + 0.33);
    return 1.0 - (0.5 * const_frac);
}

float get_oren_nayar_coef_b() {
    float microfacet_var = surf_roughness * surf_roughness;
    float scale_frac = microfacet_var / (microfacet_var + 0.09);
    return 0.45 * scale_frac;
}

float distance_fog_amt(in float current_zbuffer) {
    float contrast = exp(-fog_attenuation_coef * current_zbuffer);
    return 1.0 - contrast;
}

vec3 distance_fog_rgb_partial(in float fog_amt) {
    return fog_color * fog_amt;
}

float distance_fog_visibility_frac(in float fog_amt) {
    return 1.0 - fog_amt;
}

void main() {
    vec3 v = vert;
    camspace(v);
    vec2 pos = v.xy / v.z;

    float z = zbuffer_value(v.z);

    gl_Position = vec4(pos, z, 1.0);
    vert_color = vert;

    set_illum(illum);
    update_illum_lambertian(illum);
    illum_frag_phong_oren_nayar_to_i = normalize(lighting_light_ctr - vert);
    illum_frag_phong_oren_nayar_to_r = normalize(cam_ctr - vert);
    illum_frag_phong_oren_nayar_coef_a = get_oren_nayar_coef_a();
    illum_frag_phong_oren_nayar_coef_b = get_oren_nayar_coef_b();
    illum_frag_phong_lighting_ambient = lighting_ambient;
    illum_frag_phong_lighting_maxsc = lighting_maxsc;
    phong_surf_normal = aux_surf_normal;

    float fog_amt = distance_fog_amt(z);
    fog_component_rgb_partial = distance_fog_rgb_partial(fog_amt);
    fog_visibility_frac = distance_fog_visibility_frac(fog_amt);
}

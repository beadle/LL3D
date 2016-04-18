#include "Light.fx"
#include "Fog.fx"

cbuffer Settings
{
  float kMaxTessDist = 25.f;
  float kMinTessDist = 1.f;
  float kMaxTessFactor = 1.f;
  float kMinTessFactor = 5.f;
};

cbuffer PerFrame 
{
  AmbientLightFX      g_ambient_light;
  DirectionalLightFX  g_directional_light;
  PointLightFX        g_point_light;
  SpotLightFX         g_spot_light;
  float4x4          g_viewProj;
  float4            g_eyePosWS;
  Fog               g_fog;
};

cbuffer PerObject 
{
  float4x4 g_world;
  float4x4 g_wvp;
  float4x4 g_texTransform;
  MaterialFX g_material;
};

// Diffuse Texture
Texture2D g_diffuseTex2D;
bool g_hasDiffuseTex2D;
TextureCube g_diffuseTexCube;
bool g_hasDiffuseTexCube;

// Normal Texture
Texture2D g_normalTex;
bool g_hasNormalTex;

SamplerState g_sampler 
{
  Filter = ANISOTROPIC;
  MaxAnisotropy = 4;

  AddressU = WRAP;
  AddressV = WRAP;
};

//BlendState g_blend
//{
//    BlendEnable[0] = TRUE;
//    SrcBlend[0] = SRC_ALPHA;
//    DestBlend[0] = INV_SRC_ALPHA;
//    BlendOp[0] = ADD;
//    SrcBlendAlpha[0] = INV_DEST_ALPHA;
//    DestBlendAlpha[0] = ONE;
//    BlendOpAlpha[0] = ADD;
//    RenderTargetWriteMask[0] = 0x0F;
//};

struct VertexIn 
{
  float3 posLS  : POSITION;
  float3 normalLS : NORMAL;
  float2 texcoord : TEXCOORD;
  float3 tangentLS : TANGENT;
  float3 bitangentLS : BITANGENT;
};

struct VertexOut 
{
  float3 posWS  : POSITIONWS;
  float3 posLS  : POSITIONLS;
  
  float2 texcoord : TEXCOORD;
  
  float3 normalWS : NORMAL;
  float3 tangentWS : TANGENT;
  float3 bitangentWS : BITANGENT;

  float tessFactor : TESS;
};

VertexOut VS(VertexIn vin) 
{
  VertexOut vout;
  
  vout.posLS = vin.posLS;
  vout.posWS = mul(float4(vin.posLS, 1.f), g_world);
  vout.posPS = mul(vout.posWS, g_viewProj);
  
  vout.texcoord = mul(float4(vin.texcoord, 0.0, 1.0), g_texTransform).xy;
  
  vout.normalWS = mul(float4(vin.normalLS, 0.f), g_world).xyz;
  vout.tangentWS = mul(float4(vin.tangentLS, 0.f), g_world).xyz;
  vout.bitangentWS = mul(float4(vin.bitangentLS, 0.f), g_world).xyz;

  float d = distance(vout.posWS, g_eyePosWS);
  float tess = saturate((d - kMinTessDist) /
    (kMaxTessDist - kMinTessDist));
  vout.tessFactor = kMinTess + tess * (kMaxTessFactor - kMinTessFactor);

  return vout;
}

struct PatchTess
{
  float edgeTess[3] : SV_TessFactor;
  float insideTess : SV_InsideTessFactor;
}

PatchTess HS(InputPatch<VertexOut, 3> patch, uint patchID : SV_PrimitiveID)
{
  PatchTess pt;

  pt.edgeTess[0] = (patch[1].tessFactor + patch[2].tessFactor) / 2.f;
  pt.edgeTess[1] = (patch[2].tessFactor + patch[0].tessFactor) / 2.f;
  pt.edgeTess[2] = (patch[0].tessFactor + patch[1].tessFactor) / 2.f;

  // Arbitrarily using first edge tess as inside tess.
  pt.insideTess = pt.edgeTess[0];
}

struct HullOut
{
  float3 posWS  : POSITIONWS;
  float3 posLS  : POSITIONLS;

  float2 texcoord : TEXCOORD;

  float3 normalWS : NORMAL;
  float3 tangentWS : TANGENT;
  float3 bitangentWS : BITANGENT;
};

// Hull Shader: Simplely pass throuth.
[domain("tri")]
[partitioning("fractional_odd")]
[outputtopology("triangle_cw")]
[outputcontrolpoints(3)]
[patchconstantfunc("PatchHS")]
HullOut HS(InputPatch<VertexOut, 3> vout,
  uint i : SC_OutputControlPointID,
  unint patchID : SV_PrimitiveID)
{
  HullOut hout;

  
  hout.posWS = vout[i].posWS;
  hout.posLS = vout[i].posLS;

  hout.texcoord = vout[i].texcoord;
  
  hout.normalWS = vout[i].normalWS;
  hout.tangentWS = vout[i].tangentWS;
  hout.bitangentWS = vout[i].bitangentWS;

  return hout;
}

struct DomainOut
{
  float4 posHS : SV_POSITION;
  float3 posWS  : POSITIONWS;
  float3 posLS  : POSITIONLS;

  float2 texcoord : TEXCOORD;

  float3 normalWS : NORMAL;
  float3 tangentWS : TANGENT;
  float3 bitangentWS : BITANGENT;
}

[domain("tri")]
DomainOut DS(PatchTess patchTess,
  float3 bary : SV_DomainLocation,
  const OutputPatch<HullOut, 3> tri)
{
  DomainOut dout;

  
} 

//[maxvertexcount(2)]
//void GS(point VertexOut gin[1], inout LineStream<VertexOut> gout)
//{
//  
//}

float4 PS(VertexOut pin, uniform bool use_alpha_clip)
  : SV_Target
{
  float4 result;
  
  result.a = g_material.opacity;

  // Alpha clip
  if (use_alpha_clip) {
    clip(result.a - 0.1f);
  }

  // Shadow do not need texturing and lighting.
  if (g_material.is_shadow) {  
    result.xyz = g_material.diffuse;
    return result;
  }

  // Texture
  float3 diffuse = float3(0, 0, 0);
  if (g_hasDiffuseTex2D) {
    diffuse = g_diffuseTex2D.Sample(g_sampler, pin.texcoord).xyz;
  }
  else if (g_hasDiffuseTexCube) {
    // TexCube do not need lighting, light is contained in texture.
    return g_diffuseTexCube.Sample(g_sampler, pin.posLS);
  }
  else {
    diffuse = g_material.diffuse;
  }

  // Normal Mapping
  if (g_hasNormalTex) {
    float3 normalTS = g_normalTex.Sample(g_sampler, pin.texcoord).xyz;
    // TS (Tangent Space) -> WS (World Space)
    float3x3 TBN = float3x3(pin.tangentWS, pin.bitangentWS, pin.normalWS);
    pin.normalWS = mul(normalTS, TBN);
  }

  // Lights
  float3 viewDir = g_eyePosWS.xyz - pin.posWS.xyz;
  float3 ambient_contribution = ApplyAmbientLight(g_material, g_ambient_light);
  float3 directional_contribution = ApplyDirectionalLight(g_material, 
    g_directional_light, pin.normalWS, viewDir);
  float3 point_contribution = ApplyPointLight(g_material,
    g_point_light, pin.posWS.xyz, pin.normalWS, viewDir);
  float3 spot_contribution = ApplySpotLight(g_material,
    g_spot_light, pin.posWS.xyz, pin.normalWS, viewDir);
  
  float3 lightColor = ambient_contribution + directional_contribution +
    point_contribution + spot_contribution;

  // TODO: better way?
  result.xyz = max(lightColor, float3(0, 0, 0)) * 0.4f + diffuse * 0.6f;

  return result;

  //// Fogging
  ///*float distance_to_eye = length(to_eye);
  //float s = saturate((distance_to_eye - g_fog.start) / g_fog.range);
  //lit_color = (1 - s) * lit_color + s * g_fog.color;*/
}

technique11 Tech {
  pass P0 {
    SetVertexShader(CompileShader(vs_5_0, VS()));
    SetGeometryShader(NULL);
    SetPixelShader(CompileShader(ps_5_0, PS(false)));
  }
}

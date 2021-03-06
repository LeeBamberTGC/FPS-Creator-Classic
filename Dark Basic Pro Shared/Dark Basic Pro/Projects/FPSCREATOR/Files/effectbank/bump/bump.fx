//
// Lightmap Diffuse + Diffuse + Bump (segment bump)
//

/************* UNTWEAKABLES **************/

float4x4 WorldIT : WorldInverseTranspose;
float4x4 WorldViewProj : WorldViewProjection;
float4x4 World : World;
float4x4 ViewInv : ViewInverse;

/************* SURFACE **************/
string XFile = "x.x";

float4 FixedLightSource
<
    string UIType = "Fixed Light Source";
//> = {0.0f, 5000.0f, 0.0f, 0.0f};
> = {0.0f, 5000.0f, 0.0f, 0.0f};

float4 AmbiColor : Ambient
<
    string UIName =  "Ambient Light Color";
> = {0.5f, 0.5f, 0.5f, 1.0f};

float Bumpy
<
    string UIType = "slider";
    float UIMin = 0.0;
    float UIMax = 10.0;
    float UIStep = 0.1;
    string UIName =  "bump power";
> = 5.0;

/************* TEXTURES **************/

texture colorTexture : DiffuseMap
<
    string Name = "LM.tga";
    string type = "2D";
>;

texture colorTexture2 : DiffuseMap
<
    string Name = "D.tga";
    string type = "2D";
>;

texture normalTexture : DiffuseMap
<
    string Name = "N.tga";
    string type = "2D";
>;

sampler2D colorSampler = sampler_state
{
	Texture = <colorTexture>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler2D colorSampler2 = sampler_state
{
	Texture = <colorTexture2>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler2D normalSampler = sampler_state
{
	Texture = <normalTexture>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

/************* DATA STRUCTS **************/

/* data from application vertex buffer */
struct appdata {
    float3 Position	: POSITION;
    float4 UV0		: TEXCOORD0;
    float4 UV1		: TEXCOORD1;
    float4 Normal	: NORMAL;
    float4 Tangent	: TANGENT0;
    float4 Binormal	: BINORMAL0;
};

/* data passed from vertex shader to pixel shader */
struct vertexOutput {
    float4 HPosition	: POSITION;
    float4 TexCoord0	: TEXCOORD0;
    float4 TexCoord1	: TEXCOORD1;
    float3 LightVec	: TEXCOORD2;
    float3 WorldNormal	: TEXCOORD3;
    float3 WorldTangent	: TEXCOORD4;
    float3 WorldBinorm	: TEXCOORD5;
};

/*********** vertex shader ******/

vertexOutput mainVS(appdata IN)
{
    vertexOutput OUT;
    OUT.WorldNormal = normalize(mul(IN.Normal, WorldIT).xyz);
    OUT.WorldBinorm = normalize(mul(IN.Binormal, WorldIT).xyz);
    OUT.WorldTangent = normalize(mul(IN.Tangent, WorldIT).xyz);
    float4 tempPos = float4(IN.Position.x,IN.Position.y,IN.Position.z,1.0);
    float3 worldSpacePos = mul(tempPos, World).xyz;
    OUT.LightVec = normalize ( FixedLightSource - worldSpacePos );
    OUT.TexCoord0 = IN.UV0;
    OUT.TexCoord1 = IN.UV1;
    OUT.HPosition = mul(tempPos, WorldViewProj);
    return OUT;
}

/********* pixel shader ********/

float4 mainPS(vertexOutput IN) : COLOR
{
    float4 map = tex2D(colorSampler2,IN.TexCoord0.xy);
    float3 bumps = Bumpy * (tex2D(normalSampler,IN.TexCoord0.xy).xyz-(0.5).xxx);
    float3 Ln = IN.LightVec;
    float3 Nn = IN.WorldNormal;
    float3 Bn = IN.WorldBinorm;
    float3 Tn = cross ( Nn, Bn );
    float3 Nb = Nn + (bumps.x * Tn + bumps.y * Bn);
    Nb = normalize(Nb);

    float4 mapcolor = map * (0.5+dot(Ln,Nb));
    float intensity = dot(Ln,Nb) * (AmbiColor*0.5);
    float4 result = (mapcolor * (tex2D(colorSampler,IN.TexCoord1.xy)+AmbiColor)) + intensity;

    result.w = map.w;

    return result;
}

/****** technique *******/

technique dx9textured
{
	pass p0 
	{		
	        // lighting
	        Lighting       = FALSE;
	        SpecularEnable = FALSE;
	        FogEnable      = FALSE;

		// same vertex shader for both DX9 techniques
		VertexShader = compile vs_1_1 mainVS();
		PixelShader = compile ps_2_0 mainPS();
	}
}

/***************************** eof ***/

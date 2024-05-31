namespace Fanfare {
    DTexture@[] fwParticles;

    void AddFireworkParticle(DTexture@ dtex) {
        fwParticles.InsertLast(@dtex);
    }

    DTexture@ ChooseRandomParticleTex() {
        if (fwParticles.Length == 0) return null;
        return fwParticles[Math::Rand(0, fwParticles.Length)];
    }

    void OnFinishHit() {
        startnew(RunFinishFanfare);
    }

    void RunFinishFanfare() {
        // finish stutters
        yield(6);
        EmitStatusAnimation(FinishFireworksFanfareAnim());
    }

    void LoadDefaultFanfareTextures() {
        // fwParticles.InsertLast();
        // todo
    }
}


// Meta animation to wrap individual firework animations
class FinishFireworksFanfareAnim : ProgressAnim {
    uint nbFireworks;
    uint durationMs;
    uint particles;
    uint nbSpawned = 0;

    FinishFireworksFanfareAnim(uint nbFireworks = 40, uint durationMs = 20000, uint particles=20) {
        super("MultiFireworks", nat2(0, durationMs));
        this.nbFireworks = nbFireworks;
        this.durationMs = durationMs;
        this.particles = particles;
    }

    void Reset() override {
        ProgressAnim::Reset();
        nbSpawned = 0;
    }

    bool Update() override {
        auto expectedSpawned = nbFireworks * progressMs / durationMs;
        if (nbSpawned < expectedSpawned) {
            nbSpawned++;
            EmitStatusAnimation(FireworkAnim());
        }
        return ProgressAnim::Update();
    }
}

uint fireworkCount = 0;
const uint fireworkExplosionDuration = 200;
const uint fireworkFloatDuration = 2000;
const uint fireworkDisappearRandPlusMinus = 500;
const uint fireworkTotalDuration = fireworkExplosionDuration + fireworkFloatDuration + fireworkDisappearRandPlusMinus;

const float fwExplPropDur = float(fireworkExplosionDuration) / float(fireworkTotalDuration);

float g_FireworkExplosionRadius = 0.2;
float g_FireworkInitVel = 0.0015;

class FireworkAnim : ProgressAnim {
    FireworkAnim() {
        auto totalDur = fireworkExplosionDuration + fireworkFloatDuration + fireworkDisappearRandPlusMinus;
        super("Firework " + (++fireworkCount), nat2(0, totalDur));
    }

    void Reset() override {
        ProgressAnim::Reset();
    }

    void UpdateInner() override {

    }
}






class FireworkParticle {
    vec2 pos;
    vec2 basePos;
    vec2 vel;
    // float size;
    // float alpha;
    // float rotation;
    // float rotationSpeed;
    // float floatSpeed;
    // float floatHeight;
    // float disappearTime;
    // bool disappeared = false;
    DTexture@ dtex;

    float initTheta;
    float t_fall;
    uint createdAt;

    // vec2 vel, float size, float alpha, float rotation, float rotationSpeed, float floatSpeed, float floatHeight, float disappearTime
    FireworkParticle(vec2 basePos = vec2(0.0)) {
        this.basePos = basePos;
        this.pos = vec2(0.0);
        // this.vel = vel;
        // this.size = size;
        // this.alpha = alpha;
        // this.rotation = rotation;
        // this.rotationSpeed = rotationSpeed;
        // this.floatSpeed = floatSpeed;
        // this.floatHeight = floatHeight;
        // this.disappearTime = disappearTime;
        // this.dtex = dtex;
        createdAt = Time::Now;
        initTheta = Math::Rand(0.0, TAU);
        vel = g_FireworkInitVel * Vec2CosSin(initTheta) * Math::Rand(0.3, 1.0);
        @dtex = Fanfare::ChooseRandomParticleTex();
    }

    vec2 GetDrawPos() {
        // pos and basePos are in range [-1, 1] for y (x is [-a, a] where a is aspect)
        return ((pos + basePos) * g_screen.y + g_screen) * .5;
    }

    void UpdatePos(float t) {
        t_fall = t - fwExplPropDur;
        pos += vel * g_DT;
        if (t > fwExplPropDur / 3.) {
            vel -= (vel * 0.0365) * g_DT * 0.05;
            vel.y = vel.y + (GRAV - vel.y * 0.02) * g_DT * 0.05;
        }
    }

    // vec2 GetExplosionPos(float t) {
    //     pos = g_FireworkExplosionRadius * t * vec2(Math::Cos(initTheta), Math::Sin(initTheta));
    //     return pos;
    // }

    // vec2 GetFallingPos(float t) {
    //     auto initVel = vec2(Math::Cos(initTheta), Math::Sin(initTheta))
    //         * g_FireworkExplosionRadius / fwExplPropDur;
    //     pos.x = initVel.x * t_fall;
    //     pos.y = initVel.y * t_fall + 0.5 * GRAV * t_fall**2;
    //     return pos;
    // }
}

const float GRAV = 0.00002;


vec2 Vec2CosSin(float theta) {
    return vec2(Math::Cos(theta), Math::Sin(theta));
}

FireworkParticle@[] testFWParticles;


bool g_DrawFireworks;

void RenderFireworkTest() {
    if (!g_DrawFireworks) return;
    if (testFWParticles.Length == 0) return;

    auto uv = vec2();
    uv = uv * g_screen.y * .5;
    uv = uv + g_screen / 2.;
    // nvgDrawCircle(uv);
    // nvgDrawCircle((vec2(.25, 0) * g_screen.y + g_screen) * .5);
    // nvgDrawCircle((vec2(0, .25) * g_screen.y + g_screen) * .5);
    // nvgDrawCircle((vec2(.25, .25) * g_screen.y + g_screen) * .5);
    float aspect = g_screen.x / g_screen.y;
    auto newBasePos = vec2(Math::Rand(-aspect*.8, aspect*.8), Math::Rand(-0.9, 0.19));

    for (uint i = 0; i < testFWParticles.Length; i++) {
        auto fw = testFWParticles[i];

        float t = float(Time::Now - fw.createdAt) / float(fireworkTotalDuration);
        fw.UpdatePos(t);
        // trace('t = ' + t + ' / pos = ' + fw.pos.ToString() + ' / basePos = ' + fw.basePos.ToString() + ' / createdAt = ' + fw.createdAt + ' / now = ' + Time::Now + ' / totalDur = ' + fireworkTotalDuration);
        nvgDrawCircle(fw.GetDrawPos());
        // trace("cAt - Now / dur = " + float(Time::Now - fw.createdAt) + " / " + float(fireworkTotalDuration) + " = " + float(Time::Now - fw.createdAt) / float(fireworkTotalDuration));
        if (t > 1.0) {
            // trace('new particle @ t = ' + t + ' / createdAt = ' + fw.createdAt + ' / now = ' + Time::Now + ' / totalDur = ' + fireworkTotalDuration);
            @testFWParticles[i] = FireworkParticle(newBasePos);
        }
    }
}

void nvgDrawCircle(vec2 pos) {
    nvg::Reset();
    nvg::BeginPath();
    nvg::FillColor(cGreen);
    nvg::StrokeColor(cMagenta);
    nvg::Circle(pos, 10);
    nvg::Fill();
    nvg::Stroke();
    nvg::ClosePath();
}

void RunFireworksTest() {
    sleep(1000);
    trace('starting fw test');
    g_DrawFireworks = true;
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
    testFWParticles.InsertLast(FireworkParticle());
}

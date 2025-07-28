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

    DTexture@ FanfareSpritesheet;

    void LoadDefaultFanfareTextures() {
        if (fwParticles.Length > 0) return;
        if (FanfareSpritesheet is null) {
            @FanfareSpritesheet = DTexture("img/fanfare-spritesheet.png");
        }
        fwParticles.Reserve(20);
        for (uint row = 0; row < 2; row++) {
            for (uint col = 0; col < 10; col++) {
                if (row == 1 && col >= 7) continue;
                AddFireworkParticle(FanfareSpritesheet.GetSprite(nat2(col * 60, row * 60), nat2(60, int(59.5))));
            }
        }
        AddFireworkParticle(FanfareSpritesheet.GetSprite(nat2(420, 60), nat2(180, int(59.5))));
    }
}


// Meta animation to wrap individual firework animations
class FinishFireworksFanfareAnim : ProgressAnim {
    uint nbFireworks;
    uint durationMs;
    uint particles;
    uint nbSpawned = 0;

    FinishFireworksFanfareAnim(uint nbFireworks = 80, uint durationMs = 55000, uint particles=40) {
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
        uint expectedSpawned = nbFireworks * progressMs / durationMs;
        if (nbSpawned < expectedSpawned) {
            nbSpawned++;
            EmitStatusAnimation(FireworkAnim(particles));
        }
        return ProgressAnim::Update();
    }
}

uint fireworkCount = 0;
const uint fireworkExplosionDuration = 200;
const uint fireworkFloatDuration = 4000;
const uint fireworkDisappearRandPlusMinus = 600;
const uint fireworkTotalDuration = fireworkExplosionDuration + fireworkFloatDuration + fireworkDisappearRandPlusMinus;

const float fwExplPropDur = float(fireworkExplosionDuration) / float(fireworkTotalDuration);

float g_FireworkExplosionRadius = 0.2;
float g_FireworkInitVel = 0.0015;

vec2 lastBasePos;

class FireworkAnim : ProgressAnim {
    FireworkParticle@[] particles;
    vec2 basePos;
    FireworkAnim(uint nbParticles) {
        auto totalDur = fireworkExplosionDuration + fireworkFloatDuration + fireworkDisappearRandPlusMinus;

        float aspect = g_screen.x / g_screen.y;
        do {
            basePos = vec2(Math::Rand(-aspect*.8, aspect*.8), Math::Rand(-0.9, 0.19));
        } while ((basePos - lastBasePos).LengthSquared() < 0.7);
        lastBasePos = basePos;

        super("Firework " + (++fireworkCount), nat2(0, totalDur));
        for (uint i = 0; i < nbParticles; i++) {
            particles.InsertLast(FireworkParticle(basePos));
        }
    }

    void Reset() override {
        ProgressAnim::Reset();
    }

    void UpdateInner() override {
        for (uint i = 0; i < particles.Length; i++) {
            particles[i].UpdatePos(t);
        }
    }

    vec2 Draw() override {
        for (uint i = 0; i < particles.Length; i++) {
            particles[i].Draw();
        }
        return vec2();
    }
}






class FireworkParticle {
    vec2 pos;
    vec2 basePos;
    vec2 vel;
    DTexture@ dtex;

    float initTheta;
    float t_fall;
    uint createdAt;
    float angularVel;
    float angularResistance;
    float rot;
    float airResistance;
    float gravMod = 1.0;
    float limit = 1.0;

    FireworkParticle(vec2 basePos = vec2(0.0)) {
        this.basePos = basePos;
        this.pos = vec2(0.0);
        createdAt = Time::Now;
        airResistance = Math::Rand(0.026, 0.0365);
        gravMod = Math::Rand(0.9, 1.1);
        initTheta = Math::Rand(0.0, TAU);
        rot = Math::Rand(0.0, TAU);
        angularResistance = Math::Rand(0.02, 0.035);
        angularVel = Math::Rand(.5, 1.0) * (float(Math::Rand(0, 2)) - .5) * 2.;
        vel = g_FireworkInitVel * Vec2CosSin(initTheta) * Math::Rand(0.3, 1.0);
        @dtex = Fanfare::ChooseRandomParticleTex();
        limit = 1.0 - Math::Rand(0.0, (float(fireworkDisappearRandPlusMinus * 2.) / float(fireworkTotalDuration)));
        if (dtex is null) {
            dev_trace('no dtex');
        }
    }

    vec2 GetDrawPos() {
        // pos and basePos are in range [-1, 1] for y (x is [-a, a] where a is aspect)
        return ((pos + basePos) * g_screen.y + g_screen) * .5;
    }

    vec2 size, origDrawPos, drawPos;

    void Draw() {
        if (lastT > limit) return;
        if (dtex is null) {
            nvgDrawCircle(GetDrawPos());
            return;
        }
        origDrawPos = GetDrawPos();
        drawPos = origDrawPos - size / 2.;
        size = dtex.GetSize();
        nvg::Reset();
        nvg::BeginPath();
        nvg::Translate(origDrawPos);
        nvg::Rotate(rot);
        nvg::Translate(origDrawPos * -1.);
        nvg::Rect(drawPos, size);
        // nvg::Rect(vec2(), g_screen);
        nvg::FillPaint(dtex.GetPaint(drawPos, size, 0., 1.));
        nvg::Fill();
        nvg::ClosePath();
    }

    float lastT;
    void UpdatePos(float t) {
        lastT = t;
        t_fall = t - fwExplPropDur;
        pos += vel * g_DT;
        if (t > fwExplPropDur / 3.) {
            // 0.0365
            vel -= (vel * airResistance) * g_DT * 0.05;
            vel.y = vel.y + (GRAV * gravMod - vel.y * 0.02) * g_DT * 0.05;
        }
        rot += angularVel * g_DT * 0.05;
        // 0.03
        angularVel = angularVel - angularVel * angularResistance * g_DT * 0.05;
    }
}

const float GRAV = 0.00002;


vec2 Vec2CosSin(float theta) {
    return vec2(Math::Cos(theta), Math::Sin(theta));
}

// FireworkParticle@[] testFWParticles;


// bool g_DrawFireworks = true;

// void RenderFireworkTest() {
//     if (!g_DrawFireworks) return;
//     // trace('drawing fireworks ' + testFWParticles.Length);
//     if (testFWParticles.Length == 0) return;

//     auto uv = vec2();
//     uv = (uv * g_screen.y + g_screen) * .5;
//     float aspect = g_screen.x / g_screen.y;
//     auto newBasePos = vec2(Math::Rand(-aspect*.8, aspect*.8), Math::Rand(-0.9, 0.19));

//     for (uint i = 0; i < testFWParticles.Length; i++) {
//         auto fw = testFWParticles[i];
//         if (fw is null) {
//             trace('null fw');
//             continue;
//         }

//         float t = float(Time::Now - fw.createdAt) / float(fireworkTotalDuration);
//         fw.UpdatePos(t);
//         // nvgDrawCircle(fw.GetDrawPos());
//         fw.Draw();

//         // trace('t = ' + t + ' / pos = ' + fw.pos.ToString() + ' / basePos = ' + fw.basePos.ToString() + ' / createdAt = ' + fw.createdAt + ' / now = ' + Time::Now + ' / totalDur = ' + fireworkTotalDuration);
//         // trace("cAt - Now / dur = " + float(Time::Now - fw.createdAt) + " / " + float(fireworkTotalDuration) + " = " + float(Time::Now - fw.createdAt) / float(fireworkTotalDuration));
//         if (t > 1.0) {
//             // trace('new particle @ t = ' + t + ' / createdAt = ' + fw.createdAt + ' / now = ' + Time::Now + ' / totalDur = ' + fireworkTotalDuration);
//             @testFWParticles[i] = FireworkParticle(newBasePos);
//         }
//     }
// }

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

// void RunFireworksTest() {
//     sleep(1000);
//     trace('starting fw test');
//     g_DrawFireworks = true;
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
//     testFWParticles.InsertLast(FireworkParticle());
// }

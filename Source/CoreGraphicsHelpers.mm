//
//  CoreGraphicsHelpers.m
//  Wheel
//
//  Created by Daniel Eggert on 1/1/13.
//  Copyright (c) 2013 Bödewadt. All rights reserved.
//

#import "CoreGraphicsHelpers.h"




static CGFloat bezierCurveLength(CGPoint const p[4])
{
    // <http://processingjs.nihongoresources.com/bezierinfo/>
    //
    // <http://processingjs.nihongoresources.com/bezierinfo/legendre-gauss-values.php>
    //
    size_t const n = 10;
    CGFloat const C[n] = {
        0.2955242247147529f,
        0.2955242247147529f,
        0.2692667193099963f,
        0.2692667193099963f,
        0.2190863625159820f,
        0.2190863625159820f,
        0.1494513491505806f,
        0.1494513491505806f,
        0.0666713443086881f,
        0.0666713443086881f,
    };
    CGFloat const T[n] = {
        -0.1488743389816312f,
        0.1488743389816312f,
        -0.4333953941292472f,
        0.4333953941292472f,
        -0.6794095682990244f,
        0.6794095682990244f,
        -0.8650633666889845f,
        0.8650633666889845f,
        -0.9739065285171717f,
        0.9739065285171717f,
    };
    auto f = [&](double t) -> double {
        auto base = [](double const tt, double const p1, double const p2, double const p3, double const p4){
            return (tt *
                    (tt *
                     (-3.*p1 + 9.*p2 - 9.*p3 + 3.*p4)
                     + 6.*p1 - 12.*p2 + 6.*p3)
                    - 3.*p1 + 3.*p2);
        };
        double const a = base(t, p[0].x, p[1].x, p[2].x, p[3].x);
        double const b = base(t, p[0].y, p[1].y, p[2].y, p[3].y);
        return sqrt(a*a + b*b);
    };
    double const z = 1;
    double sum = 0;
    for (size_t i = 0; i < n; ++i) {
        sum += C[i] * f(z * 0.5 * T[i] + z * 0.5);
    }
    return (CGFloat) (sum * z * 0.5);
}

struct pathLengthContext_s {
    pathLengthContext_s(void) : length(0), p(CGPointZero) {};
    CGFloat length = 0;
    CGPoint p = CGPointZero;
};
typedef struct pathLengthContext_s pathLengthContext_t;

static void pathLengthFunction(void *info, const CGPathElement *element)
{
    pathLengthContext_t * ctx = (pathLengthContext_t *) info;
    switch (element->type) {
        case kCGPathElementMoveToPoint:
            ctx->p = element->points[0];
            break;
        case kCGPathElementAddLineToPoint: {
            CGPoint p0 = element->points[0];
            ctx->length += sqrtf((p0.x - ctx->p.x) * (p0.x - ctx->p.x) +
                                 (p0.y - ctx->p.y) * (p0.y - ctx->p.y));
            ctx->p = p0;
            break;
        }
        case kCGPathElementAddQuadCurveToPoint: {
            NSCAssert(NO, @"");
            break;
        }
        case kCGPathElementAddCurveToPoint: {
            CGPoint const points[4] = {
                ctx->p,
                element->points[0],
                element->points[1],
                element->points[2],
            };
            ctx->length += bezierCurveLength(points);
            ctx->p = points[3];
            break;
        }
        case kCGPathElementCloseSubpath: {
            break; // Ignoring, although it could add a line to the first point.
        }
        default:
            break;
    }
}


CGFloat CGPath::length(void) const
{
    pathLengthContext_t ctx;
    CGPathApply(this, &ctx, pathLengthFunction);
    return ctx.length;
}

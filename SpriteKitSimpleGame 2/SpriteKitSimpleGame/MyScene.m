//
//  MyScene.m
//  SpriteKitSimpleGame
//
//  Created by Perry on 14-6-13.
//  Copyright (c) 2014年 Perrychen. All rights reserved.
//

#import "MyScene.h"


//1 create a private interface so that you can declare a private variable for the player
@interface MyScene()<SKPhysicsContactDelegate>
@property (nonatomic) SKSpriteNode * player; // ninja node
@property (nonatomic) NSTimeInterval lastSpawnTimeInterval;
@property (nonatomic) NSTimeInterval lastUpdateTimeInterval;


@end

static const uint32_t projectileCategory = 0x01 << 0;
static const uint32_t monsterCategory     = 0x01 << 1;
static inline CGPoint rwAdd(CGPoint a, CGPoint b) {
    return CGPointMake(a.x+b.x, a.y+b.y);
}

static inline CGPoint rwSub(CGPoint a, CGPoint b) {
    return CGPointMake(a.x-b.x, a.y-b.y);
}

static inline CGPoint rwMult(CGPoint a, float b) {
    return CGPointMake(a.x * b, a.y * b);
}

static inline float rwLength(CGPoint a) {
    return sqrtf(a.x*a.x + a.y*a.y);
}

static inline CGPoint rwNormlize(CGPoint a) {
    float length = rwLength(a);
    return CGPointMake(a.x / length, a.y / length);
}

@implementation MyScene

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        // 2
        NSLog(@"Size: %@", NSStringFromCGSize(size));
        
        
        // 3
        self.backgroundColor = [SKColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
        
        // 4
        self.player = [SKSpriteNode spriteNodeWithImageNamed:@"player"];
        self.player.position = CGPointMake(self.player.size.width/2, self.frame.size.height/2);
        [self addChild:self.player];
        
        
        self.physicsWorld.gravity = CGVectorMake(0, 0);
        self.physicsWorld.contactDelegate = self;
    }
    return self;
}

- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)timeSinceLast {
    self.lastSpawnTimeInterval += timeSinceLast;
    if (self.lastSpawnTimeInterval > 1) {
        self.lastSpawnTimeInterval = 0;
        [self addMonster];
    }
}
// method will be called automatically by Sprite Kit each frame.
- (void)update:(NSTimeInterval)currentTime
{
    // Handle tiem delta.
    // If we drop below 60fps, we still want everything to move the same instance
    CFTimeInterval timeSinceLast = currentTime - self.lastUpdateTimeInterval;
    self.lastUpdateTimeInterval = currentTime;
    //Note it does some sanity checking so that if an unexpectedly large amount of time has elapsed since the last frame, it resets the interval to 1/60th of a second to avoid strange behavior
    if (timeSinceLast > 1) {
        timeSinceLast = 1.0 / 60.0;
        self.lastUpdateTimeInterval = currentTime;
    }
    [self updateWithTimeSinceLastUpdate:timeSinceLast];
}

- (void)addMonster {
    SKSpriteNode * monster = [SKSpriteNode spriteNodeWithImageNamed:@"monster"];
    
    monster.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:monster.size];
    monster.physicsBody.dynamic = YES;
    monster.physicsBody.categoryBitMask = monsterCategory;
    monster.physicsBody.contactTestBitMask = projectileCategory;
    monster.physicsBody.collisionBitMask = 0;
    
    // Determine where to spawn the monster along the Y axis
    int minY = monster.size.height / 2;
    int maxY = self.frame.size.height - monster.size.height / 2;
    int rangeY = maxY - minY;
    int actualY = (arc4random() % rangeY) + minY;
    
    // create the monster slightly off-screen along the right edge. and along a random position along the Y axis as calculated above
    monster.position = CGPointMake(self.frame.size.width + monster.size.width/2, actualY);
    
    [self addChild:monster];
    
    
    
    // Determine speed of the monster
    int minDuration = 2.0;
    int maxDuration = 4.0;
    int rangeDuration = maxDuration - minDuration;
    int actualDuration = (arc4random() % rangeDuration) + minDuration;
    
    // Create the actions
    SKAction *actionMove = [SKAction moveTo:CGPointMake(-monster.size.width/2, actualY) duration:actualDuration];
    SKAction *actionMoveDone = [SKAction removeFromParent];
    [monster runAction:[SKAction sequence:@[actionMove, actionMoveDone]]];
    
    
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    //    for (UITouch *touch in touches) {
    //        CGPoint location = [touch locationInNode:self];
    //
    //        SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:@"Spaceship"];
    //
    //        sprite.position = location;
    //
    //        SKAction *action = [SKAction rotateByAngle:M_PI duration:1];
    //
    //        [sprite runAction:[SKAction repeatActionForever:action]];
    //
    //        [self addChild:sprite];
    //    }
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    // 1 - Choose one of the touches to work with
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    
    // 2 - Set up initial location of projectile
    SKSpriteNode * projectile = [SKSpriteNode spriteNodeWithImageNamed:@"projectile"];
    projectile.position = self.player.position;
    NSLog(@"position %@",NSStringFromCGPoint(projectile.position));
    // 3 - Determine offset of location to projectile
    CGPoint offset = rwSub(location, projectile.position);
    NSLog(@"offset %@",NSStringFromCGPoint(offset));
    // 4 - Bail out if you are shooting down or backwards
    if (offset.x <= 0) {
        return;
    }
    
    // 5 - OK to add now - we've double checked position
    [self addChild:projectile];
    
    // 6 - Get the direction of where to shoot
    CGPoint direction = rwNormlize(offset);
    NSLog(@"direction %@",NSStringFromCGPoint(direction));
    // 7 - Make it shoot far enough to be guaranteed off screen
    CGPoint shootAmount = rwMult(direction, 1000);
    NSLog(@"shoot amount %@",NSStringFromCGPoint(shootAmount));
    // 8 - Add the shoot amount to the current position
    CGPoint realDest = rwAdd(shootAmount, projectile.position);
    NSLog(@"realdest %@",NSStringFromCGPoint(realDest));
    // 9 - Create the actions
    float velocity = 480.0/1.0;
    float realMoveDuration = self.size.width / velocity;
    SKAction *actionMove = [SKAction moveTo:realDest duration:realMoveDuration];
    SKAction *actionMoveDone = [SKAction removeFromParent];
    [projectile runAction:[SKAction sequence:@[actionMove, actionMoveDone]]];
}

@end
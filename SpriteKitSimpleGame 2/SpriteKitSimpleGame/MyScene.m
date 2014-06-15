//
//  MyScene.m
//  SpriteKitSimpleGame
//
//  Created by Perry on 14-6-13.
//  Copyright (c) 2014年 Perrychen. All rights reserved.
//

#import "MyScene.h"
#import "GameOverScene.h"

//1 create a private interface so that you can declare a private variable for the player
@interface MyScene()<SKPhysicsContactDelegate>
@property (nonatomic) SKSpriteNode * player; // ninja node
@property (nonatomic) NSTimeInterval lastSpawnTimeInterval;
@property (nonatomic) NSTimeInterval lastUpdateTimeInterval;
@property (nonatomic) int monsterDestroyed;

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
    //Creates a physics body for the sprite. In this case, the body is defined as a rectangle of the same size of the sprite, because that’s a decent approximation for the monster.
    monster.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:monster.size];
    //Sets the sprite to be dynamic. This means that the physics engine will not control the movement of the monster – you will through the code you’ve already written (using move actions).
    monster.physicsBody.dynamic = YES;
    //Sets the category bit mask to be the monsterCategory you defined earlier.
    
    monster.physicsBody.categoryBitMask = monsterCategory;
    // The contactTestBitMask indicates what categories of objects this object should notify the contact listener when they intersect. You choose projectiles here.
    
    monster.physicsBody.contactTestBitMask = projectileCategory;
    // The collisionBitMask indicates what categories of objects this object that the physics engine handle contact responses to (i.e. bounce off of). You don’t want the monster and projectile to bounce off each other – it’s OK for them to go right through each other in this game – so you set this to 0.
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
    SKAction *loseAction = [SKAction runBlock:^{
        SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
        SKScene *gameOverScene = [[GameOverScene alloc] initWithSize:self.size won:NO];
        [self.view presentScene:gameOverScene transition:reveal];
    }];
    [monster runAction:[SKAction sequence:@[actionMove, loseAction, actionMoveDone]]];
    
    
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
    
    projectile.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:projectile.size.width/2];
    projectile.physicsBody.dynamic = YES;
    projectile.physicsBody.categoryBitMask = projectileCategory;
    projectile.physicsBody.contactTestBitMask = monsterCategory;
    projectile.physicsBody.collisionBitMask = 0;
    projectile.physicsBody.usesPreciseCollisionDetection = YES;
    
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
    
    [self runAction:[SKAction playSoundFileNamed:@"pew-pew-lei.caf" waitForCompletion:NO]];
}

/*
 
 As soon as you remove a sprite from its parent, it is no longer in the scene hierarchy so no more actions will take place from that point on. So you don’t want to remove the sprite from the scene until you’ve transitioned to the lose scene. Actually you don’t even need to call to actionMoveDone anymore since you’re transitioning to a new scene, but I’ve left it here for educational purposes. 
 */

- (void)projectile:(SKSpriteNode *)projectile didCollideWithIdentifier:(SKSpriteNode *)monster {
    NSLog(@"Hit");
    [projectile removeFromParent];
    [monster removeFromParent];
    self.monsterDestroyed++;
    if (self.monsterDestroyed > 30) {
        SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
        SKScene *gameOverScene = [[GameOverScene alloc] initWithSize:self.size won:YES];
        [self.view presentScene:gameOverScene transition:reveal];
    }
}

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    // 1 This method passes you the two bodies that collide, but does not guarantee that they are passed in any particular order. So this bit of code just arranges them so they are sorted by their category bit masks so you can make some assumptions later. This bit of code came from Apple’s Adventure sample.
    SKPhysicsBody *firstBody, *secondBody;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    } else {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    // 2 Finally, it checks to see if the two bodies that collide are the projectile and monster, and if so calls the method you wrote earlier.
    if ((firstBody.categoryBitMask & projectileCategory) != 0 && (secondBody.categoryBitMask & monsterCategory) != 0) {
        [self projectile:(SKSpriteNode *)firstBody.node didCollideWithIdentifier:(SKSpriteNode *)secondBody.node];
    }
}

@end
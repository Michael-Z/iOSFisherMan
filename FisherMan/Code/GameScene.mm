//
//  GameScene.m
//  Pick a Fish
//
//  Created by Khalid Al-Kooheji on 9/22/12.
//
//

#import "GameScene.h"
#import "MainMenuScene.h"
#import "time.h"

@interface GameScene()
{
    int level;
    BackgroundLayer *bgLayer;
    SeaLayer *seaLayer;
    CCParticleSystem* rainEmitter;
    ccTime timeOfDay_;
    float gameSpeed_;
    float timeLeft_;
    CCLabelTTF* debugLabel;
    CCLabelBMFont *timeLeftLabel;
    CGSize size;
}
-(void) initPhysics;
+(CCRenderTexture*) createStroke: (CCLabelTTF*) label   size:(float)size   color:(ccColor3B)cor;
- (void) createMenu;
- (void)showConfirmAlert;
@end

@implementation GameScene

const ccTime fixed_dt_ = 1.0f/60.0f;

+(CCScene *) scene: (int) level
{

	GameScene *scene = [GameScene node];
	scene->level = level;
    [scene startGame];
	return scene;
}

-(id)init
{
    
    self = [super init];
    if (self != nil)
    {
        level = 0;
        srandom(time(NULL));
        size = [CCDirector sharedDirector].winSize;
        gameSpeed_ = 1.0f;
        [self initPhysics];
    
        bgLayer = [BackgroundLayer nodeWithWorld:world];
        seaLayer = [SeaLayer nodeWithWorld:world];
        seaLayer->windIntensity = 1.1f;
        
        [self initRain];
        [self setWeatherCondition:kWeatherConditionClouds Enable:YES Intensity:0.5f];
        [self setWeatherCondition:kWeatherConditionRain Enable:YES Intensity:1.0f];
        [self setWeatherCondition:kWeatherConditionWind Enable:YES Intensity:seaLayer->windIntensity];
      
        
        
        debugLabel = [CCLabelTTF labelWithString:@"" fontName:@"Arial" fontSize:12];
        debugLabel.anchorPoint = ccp(0,0);
        debugLabel.position = ccp(0,size.height-20);
        [self addChild:debugLabel z:100];
        
        timeLeftLabel = [CCLabelBMFont labelWithString:@"99:99" fntFile:@"font-level.fnt"];
        [self addChild:timeLeftLabel z:100];
		timeLeftLabel.anchorPoint = ccp(0,0);
        timeLeftLabel.position = ccp(0, size.height-timeLeftLabel.contentSize.height);

		

        
        
        [self addChild:bgLayer z:0];        
        [self addChild:seaLayer z:1];
        [self createMenu];
        
        
        
        return self;
    }
    return nil;
}

- (void) startGame
{
    timeLeft_ = 100;
    [self update:fixed_dt_];
    [self scheduleUpdate];
    [[GameManager sharedGameManager] playBackgroundTrack:@"sea-waves-aifc"];
    {
        CCLabelBMFont* levelLabel = [CCLabelBMFont labelWithString:[NSString stringWithFormat:@"Level %d",level] fntFile:@"font-title1.fnt"];
        [levelLabel setScale:1];
		[self addChild:levelLabel z:100];
		levelLabel.position = ccp(size.width/2, size.height/2);
        

        id delay1 = [CCDelayTime actionWithDuration:2.0f];
        id fade1 = [CCFadeOut actionWithDuration:1.0f];
        id seqAction = [CCSequence actions:delay1,fade1,nil];
        [levelLabel runAction:seqAction];
    }
}

- (void) stopGame
{
    [[GameManager sharedGameManager] playBackgroundTrack:nil];
}

- (void) initRain
{
    rainEmitter = [CCParticleRain node];
    
    [bgLayer addChild: rainEmitter z:10];
    
    CGPoint p = rainEmitter.position;
    
    rainEmitter.position = ccp( p.x, p.y);
    rainEmitter.life = 7;
    rainEmitter.emissionRate = 20;
    rainEmitter.speed = 2;
    rainEmitter.texture = [[CCTextureCache sharedTextureCache] addImage: @"Raindrop.png"];
    rainEmitter.startSize = 10.0f;
    [rainEmitter stopSystem];
}

-(void) initPhysics
{
    timer_accumulator_ = 0;
	timeOfDay_ = sunriseStart+3*timeRatio;
	CGSize s = [[CCDirector sharedDirector] winSize];
	
	b2Vec2 gravity;
	gravity.Set(0.0f, -10.0f);
	world = new b2World(gravity,true);
	
	
	// Do we want to let bodies sleep?
	//world->SetAllowSleeping(true);
	
	world->SetContinuousPhysics(true);
	
	m_debugDraw = new GLESDebugDraw( PTM_RATIO );
	world->SetDebugDraw(NULL);
	
	uint32 flags = 0;
	flags += b2Draw::e_shapeBit;
	//		flags += b2Draw::e_jointBit;
	//		flags += b2Draw::e_aabbBit;
	//		flags += b2Draw::e_pairBit;
	//		flags += b2Draw::e_centerOfMassBit;
	m_debugDraw->SetFlags(flags);
	
	
	// Define the ground body.
	b2BodyDef groundBodyDef;
	groundBodyDef.position.Set(0,0); // bottom-left corner
	
	// Call the body factory which allocates memory for the ground body
	// from a pool and creates the ground box shape (also from a pool).
	// The body is also added to the world.
    
	b2Body* groundBody = world->CreateBody(&groundBodyDef);
	
	// Define the ground box shape.
	b2EdgeShape groundBox;
	
	// bottom
	
	groundBox.Set(b2Vec2(0,ptm(-s.height)), b2Vec2(ptm(s.width),ptm(-s.height)));
	groundBody->CreateFixture(&groundBox,0);
	
	// top
	groundBox.Set(b2Vec2(0,s.height/PTM_RATIO), b2Vec2(s.width/PTM_RATIO,s.height/PTM_RATIO));
	groundBody->CreateFixture(&groundBox,0);
	
	// left
	groundBox.Set(b2Vec2(0,s.height/PTM_RATIO), b2Vec2(0,0));
	groundBody->CreateFixture(&groundBox,0);
	
	// right
	groundBox.Set(b2Vec2(s.width/PTM_RATIO,s.height/PTM_RATIO), b2Vec2(s.width/PTM_RATIO,0));
	groundBody->CreateFixture(&groundBox,0);
}

+(CCRenderTexture*) createStroke: (CCLabelTTF*) label   size:(float)size   color:(ccColor3B)cor
{
	CCRenderTexture* rt = [CCRenderTexture renderTextureWithWidth:label.texture.contentSize.width+size*2  height:label.texture.contentSize.height+size*2];
	CGPoint originalPos = [label position];
	ccColor3B originalColor = [label color];
	[label setColor:cor];
	ccBlendFunc originalBlend = [label blendFunc];
	[label setBlendFunc:(ccBlendFunc) { GL_SRC_ALPHA, GL_ONE }];
	CGPoint center = ccp(label.texture.contentSize.width/2+size, label.texture.contentSize.height/2+size);
	[rt begin];
	for (int i=0; i<360; i+=15)
	{
		[label setPosition:ccp(center.x + sin(CC_DEGREES_TO_RADIANS(i))*size, center.y + cos(CC_DEGREES_TO_RADIANS(i))*size)];
		[label visit];
	}
	[rt end];
	[label setPosition:originalPos];
	[label setColor:originalColor];
	[label setBlendFunc:originalBlend];
	[rt setPosition:originalPos];
	return rt;
}

-(void) createMenu
{
	// Default font size will be 22 points.
	[CCMenuItemFont setFontSize:22];
	
    
	// Reset Button
    //CCMenuItemImage* test = [CCMenuItemImage itemWithNormalImage:@"Icon.png" selectedImage:@"Icon-72.png"];
	CCMenuItemLabel *quitItem = [CCMenuItemFont itemWithString:@"Main Menu" block:^(id sender){
		//[[CCDirector sharedDirector] replaceScene: [GameScene node]];
        [self showConfirmAlert];
	}];
	
    quitItem.color = ccc3(0,0,0);
	
    
    //CCLabelTTF* label = [CCLabelTTF labelWithString: @"Some Text"
     //                              dimensions:CGSizeMake(305,179) hAlignment:kCCTextAlignmentLeft
     //                                fontName:@"Arial" fontSize:23];
    //[label setPosition:ccp(167,150)];
    //[label setColor:ccWHITE];
    //CCRenderTexture* stroke = [GameScene createStroke:label  size:2  color:ccc3(255,0,255)];
    //[self addChild:stroke];
    //[self addChild:label];
    //CCMenuItemSprite* spriteItem = [CCMenuItemSprite itemWithNormalSprite:[stroke sprite] selectedSprite:label];
	
    
    CCMenu *menu = [CCMenu menuWithItems:quitItem, nil];
	
	[menu alignItemsVertically];
	
	CGSize size = [[CCDirector sharedDirector] winSize];
	[menu setPosition:ccp( size.width-65, size.height-24)];
	
    
    [self addChild: menu z:100];
}

- (void) draw
{
    [super draw];
    
    //ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position );
    //kmGLPushMatrix();
	//world->DrawDebugData();
	//kmGLPopMatrix();
}

- (void) setWeatherCondition: (WeatherCondition) cond Enable:(BOOL) enable Intensity: (float) intensity
{
    if (cond == kWeatherConditionRain)
    {
        rainEmitter.emissionRate = intensity * 50.0f;
        if (enable == YES)
            [rainEmitter resetSystem];
        else
            [rainEmitter stopSystem];
    }
    [bgLayer setWeatherCondition:cond Enable:enable Intensity:intensity];
    [seaLayer setWeatherCondition:cond Enable:enable Intensity:intensity];
}

- (void) update: (ccTime) dt
{
    
    timer_accumulator_ += dt;
    
    int32 velocityIterations = 8;
    int32 positionIterations = 1;
    
    while ( timer_accumulator_ >= fixed_dt_ )
    {
        [debugLabel setString:[NSString stringWithFormat:@"time of day: %03.3f",timeOfDay_/timeRatio]];
        [timeLeftLabel setString:[NSString stringWithFormat:@"%03.0f ",timeLeft_]];
        timeLeft_ -= fixed_dt_;
        
        bgLayer.timeOfDay = timeOfDay_;
        seaLayer.timeOfDay = timeOfDay_;
        [bgLayer update:fixed_dt_*gameSpeed_];
        [seaLayer update:fixed_dt_*gameSpeed_];  
        // Instruct the world to perform a single step of simulation. It is
        // generally best to keep the time step and iterations fixed.
        world->Step(fixed_dt_*gameSpeed_, velocityIterations, positionIterations);
        
        timeOfDay_ += fixed_dt_*gameSpeed_;
        if (timeOfDay_ > daySeconds)
        {
            timeOfDay_ = 0.0f;
            [self setWeatherCondition:kWeatherConditionClouds Enable:NO Intensity:0.5f];
            [self setWeatherCondition:kWeatherConditionRain Enable:NO Intensity:1.0f];
            [self setWeatherCondition:kWeatherConditionWind Enable:YES Intensity:0.2f];
        }
        timer_accumulator_ -= fixed_dt_;
    }
	
}


- (void)showConfirmAlert
{
    
    [rainEmitter pauseSchedulerAndActions];
    [self pauseSchedulerAndActions];
	UIAlertView *alert = [[UIAlertView alloc] init];
	[alert setTitle:@"Confirm"];
	[alert setMessage:@"Are you sure you want to quit your game and go back to the main menu?"];
	[alert setDelegate:self];
	[alert addButtonWithTitle:@"Yes"];
	[alert addButtonWithTitle:@"No"];
	[alert show];
	[alert release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 0)
	{
		//[[CCDirector sharedDirector] replaceScene:[CCTransitionRotoZoom transitionWithDuration:1.0 scene:[MainMenuLayer scene]]];
    	//[[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:1.0 scene:[MainMenuScene scene] withColor:ccWHITE]];
        [[GameManager sharedGameManager] runSceneWithID:kMainMenuScene];
	}
	else if (buttonIndex == 1)
	{
        [rainEmitter resumeSchedulerAndActions];
		[self resumeSchedulerAndActions];
	}
}

-(void) dealloc
{
    [self stopGame];
    [super dealloc];
    
	delete world;
	world = NULL;
	
	delete m_debugDraw;
	m_debugDraw = NULL;
	
}

@end
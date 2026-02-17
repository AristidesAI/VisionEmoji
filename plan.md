we are creating an iOS vision app that takes the users camera feed, and uses apples vision learning model to detect objects in the camera feed, and then uses the detected objects to generate emojis that are displayed on top of the objects in the camera feed, Specifically:

1. The app will use the users camera feed as the input
2. The app will use apples vision learning model to detect objects in the camera feed
3. The app will use the detected objects to play animated gif emojis on repeat until the live model detects a new object/feature


Tracked Features:
- Face movements, Smiles, Frowns, Winks, Every trackable facial feature that lines up with a emoji
- body movements, Dancing, Running, Jumping, Every trackable body feature that lines up with a emoji
- Hand movements, Every trackable hand feature that lines up with a emoji
- Objects (cars, people, animals, etc.)


in order the priority of vision components:
Object tracking and having the emoji follow the object is the highest priority, Identify objects and place emojis on them in realtime, When the object moves in camera frame, Move the emoji to follow the object, When the object leaves the camera frame, Remove the emoji from the screen by quickly fading the emoji out.
After object tracking and emoji pinning is working, We will focus on other vision components, such as face tracking, body tracking, hand tracking, and object tracking.

Users can change the camera feed to use the front or back facing camera, Along with all cameras including the wide angle and zoom, In scene where multiple objects are detected, the app will track the emojis onto those objects as the camera moves, Detect new objects and add new emojis at the center of the tracked objects reference point.

Users can turn on and off the background vision model, and the object detection model, and the face detection model, and the body detection model, and the hand detection model.

we will be using googles animated emoji's https://googlefonts.github.io/noto-emoji-animation/ figure out a method of downloading all the animated emojis programmatically into this project. Download the files as gif's and store them in the app.

Use apples iOS 26 liquid Glass UI, Use a very minimal UI with a camera feed in the background, and a bottom toolbar at the bottom of the screen that opens up to a context menu with a toggle for each of the models, and a toggle for the camera feed, and a toggle for the background vision model, Users can toggle multiple models on at the same time, all settings can be adjusted from this menu. 
track each vision models effect on performance through a live performance tracker displayed next to its name and toggle in the context menu. 

Swipe left from the camera view to access a settings pane. seperate view controller to access things like kalman filtering settings, and other settings that are not related to the camera feed. Include a "made by Aristides Lintzeris" label in the settings pane. 

Swipe to the left to access the settings panel, swipe to the right to access the camera feed.

The app will be ingesting a lot of data from tracking all those features at once, and will need to be optimized to handle the data efficiently. During development focus on efficiency and performance optimization. Newer devices with CoreML capabilities in hardware will take advantage.





## Errors, Bugs, and Issues:




-the gifs are still failing to load in console:
Failed to load GIF for code: all gifs are failling to load. 

- the active tracker indicator is broken and changes randomly

- I see the problem with the object tracking by enabling the view, See screenshots folder, the vision model is only tracking a large object in the center of the display, rather than tracking each object as a seperate entity. 
- Improve the vision model so it tracks each target seperately, use different overlays to identify the different vision models that are tracking. e.g the object tracking model overlay should be green, The hand tracking overlay should be red, the face tracking overlay should be blue, etc.

- Improve the object recognition, Improve the facial recognition and hand gestures. Change the object tracking focus to the entire frame and track each object with equal compute.

- determine a better method of displaying the gifs onscreen in a way that loads them properly, Fades them in and out as the objects change, 

- Focus on performance improvements, Object tracking improvements. Use improved logic around vision tracking e.g: disable face/ hand tracking when using the front facing camera, disable object, building, car tracking when users are in the front facing camera.

Ensure the app performs at 30FPS minimum, Improve the performance when using UI elements, The settings tab freezes when opened, ensure optimal performance and use multithreading to improve it.

- the app runs incredibly slow, Determine a method for optimization
- the emoji's are not being displayed, grey boxes are being displayed instead, The emoji's grew squares are rotating the emoji's, Once an emoji is mapped to an object its position can change but its rotation should remain locked to that object, It can scale as the object gets larger or smaller in the frame. 
- the emojis are only spawning in the center of the display, Each emoji should be tracked to the object it is identifying. For example if you hold the camera up to the street and a car drives past, The car gif should be locked to that cars position and move as the car moves. 

- dont use the apple emoji's use the animated gif emoji's always. 

Only EVER display 5 emojis onscreen, Tracking maximum of 5 objects per camera scene. When the emoji changes fade the old emoji out and fade the new one into it new location. 

Focus on improving the FPS performance, Target 60FPS, Track emoji's to their object and fade them in and out natually. 
The face emojis that are recognizing facial expressions should appear on the users forhead so they dont cover the users face.

## additional dev context:

- the app was built with gemini-flash-3, but the vision service is not working correctly, I have deleted the two files that were created by the gemini-flash-3 tool, your job is to rewrite these features from scratch with the parameters described in the plan.
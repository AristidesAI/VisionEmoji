we are creating an iOS vision app that uses YOLO26 quantized model to detect objects in the camera feed, and then uses the detected objects to place iOS emojis that are displayed on top of the objects in the camera feed, Specifically:

Classification: Yolo26m - CLS model for image classification https://docs.ultralytics.com/tasks/classify/

Detect: Yolo26m.pt model for object detection https://docs.ultralytics.com/tasks/detect/

Detect & image output streams combined to display emojis on top of objects in the camera feed, Detect to identify suitable objects, And classifcation to specify the object type, color, and other attributes.


The camera is set to the ultrawide back facing camera to provide the best possible view of the objects in the environment, and maximise the amount of data, Implement a feature that understand the iPhone 16 Plus ultrawide camera sensor size and aspect ratio to warp the output to account for the lens distortion 


<<<<<<< HEAD

=======
Users can change the camera feed to use the front or back facing camera, Along with all cameras including the wide angle and zoom, In scene where multiple objects are detected, the app will track the emojis onto those objects as the camera moves, Detect new objects and add new emojis at the center of the tracked objects reference point.
>>>>>>> parent of b614d2fa (1.0)

Use apples iOS 26 liquid Glass UI, Use a very minimal UI with a camera feed in the background, and a bottom toolbar at the bottom of the screen that opens up to a context menu with a toggle for each of the models, and a toggle for the camera feed, and a toggle for the background vision model, all settings can be adjusted from this menu. 
track each vision models effect on performance through a live performance tracker displayed next to its name and toggle in the context menu. 




The app will be ingesting a lot of data from tracking all those features at once, and will need to be optimized to handle the data efficiently. Focus on performance optimization to get as close to real time as possible, Use the iPhone 16 Plus chip specification to guide the optimization process, and focus on using the hardware to its fullest potential.





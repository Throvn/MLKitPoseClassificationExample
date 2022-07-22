# MLKitPoseClassificationExample

## Coming back soon! This repo is currently under review by my employer.
Due to recent changes in my job, this repo has to be reviewed by my employer.
I will get it as soon as possible back out there but the process could still last about 2 months.

This repo utilizes the MLKit PoseDetection, to classify *pushups* and *squats*.
It showcases how to implement the k-nn algorithm on top of BlazePose (since Google unfortunately only implemented it in the Android sample app).

I know that a lot of people would like to play around with pose classification but don't have the time to map the Java code to Swift themselves, so feel free to clone the repo, fork it or copy it.

[Here](https://google.github.io/mediapipe/solutions/pose_classification) is the corresponding article.

## Usage

1. Open a terminal folder and cd into the project root (`MLKitPoseClassificationExample`).
2. Run `pod install` (Note if this fails, try `arch -x86_64 pod install`, this is not related to this repo but rather apples new arm chip)
3. Open the newly created `MLKitPoseClassificationExample.xcworkspace`
4. The camera should open and you should see your skeleton. -> Do some squats, or pushups and look at the console to see the results.

> Note: The classification results are currently only printed to the console.

**Tip:** The entry point of the algorithm is the `PoseClassifierProcessor`. I would start digging into the code from there.

The default model used is `MLKitPoseDetection` the implementation should also work with `MLKitPoseDetectionAccurate` but I didn't test it yet.

## Contributions

Contributions are always welcome. 

If you find a bug you which you can fix yourself or have performance improvements, PRs are welcome.

I want to keep this app to the bare minimum, so everyone can get familiar with the code pretty fast.

//
//  Rig.cpp
//  libraries/animation/src/
//
//  Created by Howard Stearns, Seth Alves, Anthony Thibault, Andrew Meadows on 7/15/15.
//  Copyright (c) 2015 High Fidelity, Inc. All rights reserved.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

#include "Rig.h"

#include <glm/gtx/vector_angle.hpp>
#include <queue>
#include <QScriptValueIterator>

#include <NumericalConstants.h>
#include <DebugDraw.h>

#include "AnimationLogging.h"
#include "AnimSkeleton.h"
#include "AnimClip.h"
#include "IKTarget.h"

static bool isEqual(const glm::vec3& u, const glm::vec3& v) {
    const float EPSILON = 0.0001f;
    return glm::length(u - v) / glm::length(u) <= EPSILON;
}

static bool isEqual(const glm::quat& p, const glm::quat& q) {
    const float EPSILON = 0.00001f;
    return 1.0f - fabsf(glm::dot(p, q)) <= EPSILON;
}

#ifdef NDEBUG
#define ASSERT(cond)
#else
#define ASSERT(cond)                            \
    do {                                        \
        if (!(cond)) {                          \
            int* ptr = nullptr;                 \
            *ptr = 10;                          \
        }                                       \
    } while (0)
#endif

/*
const glm::vec3 DEFAULT_RIGHT_EYE_POS(-0.3f, 1.6f, 0.0f);
const glm::vec3 DEFAULT_LEFT_EYE_POS(0.3f, 1.6f, 0.0f);
const glm::vec3 DEFAULT_HEAD_POS(0.0f, 1.55f, 0.0f);
const glm::vec3 DEFAULT_NECK_POS(0.0f, 1.5f, 0.0f);
*/

// 2 meter tall dude
const glm::vec3 DEFAULT_RIGHT_EYE_POS(-0.3f, 1.9f, 0.0f);
const glm::vec3 DEFAULT_LEFT_EYE_POS(0.3f, 1.9f, 0.0f);
const glm::vec3 DEFAULT_HEAD_POS(0.0f, 1.75f, 0.0f);
const glm::vec3 DEFAULT_NECK_POS(0.0f, 1.70f, 0.0f);

void Rig::overrideAnimation(const QString& url, float fps, bool loop, float firstFrame, float lastFrame) {

    // find an unused AnimClip clipNode
    std::shared_ptr<AnimClip> clip;
    if (_userAnimState == UserAnimState::None || _userAnimState == UserAnimState::B) {
        _userAnimState = UserAnimState::A;
        clip = std::dynamic_pointer_cast<AnimClip>(_animNode->findByName("userAnimA"));
    } else if (_userAnimState == UserAnimState::A) {
        _userAnimState = UserAnimState::B;
        clip = std::dynamic_pointer_cast<AnimClip>(_animNode->findByName("userAnimB"));
    }

    // set parameters
    clip->setLoopFlag(loop);
    clip->setStartFrame(firstFrame);
    clip->setEndFrame(lastFrame);
    const float REFERENCE_FRAMES_PER_SECOND = 30.0f;
    float timeScale = fps / REFERENCE_FRAMES_PER_SECOND;
    clip->setTimeScale(timeScale);
    clip->loadURL(url);

    _currentUserAnimURL = url;

    // notify the userAnimStateMachine the desired state.
    _animVars.set("userAnimNone", false);
    _animVars.set("userAnimA", _userAnimState == UserAnimState::A);
    _animVars.set("userAnimB", _userAnimState == UserAnimState::B);
}

void Rig::restoreAnimation() {
    if (_currentUserAnimURL != "") {
        _currentUserAnimURL = "";
        // notify the userAnimStateMachine the desired state.
        _animVars.set("userAnimNone", true);
        _animVars.set("userAnimA", false);
        _animVars.set("userAnimB", false);
    }
}

QStringList Rig::getAnimationRoles() const {
    if (_animNode) {
        QStringList list;
        _animNode->traverse([&](AnimNode::Pointer node) {
            // only report clip nodes as valid roles.
            auto clipNode = std::dynamic_pointer_cast<AnimClip>(node);
            if (clipNode) {
                // filter out the userAnims, they are for internal use only.
                if (!clipNode->getID().startsWith("userAnim")) {
                    list.append(node->getID());
                }
            }
            return true;
        });
        return list;
    } else {
        return QStringList();
    }
}

void Rig::overrideRoleAnimation(const QString& role, const QString& url, float fps, bool loop, float firstFrame, float lastFrame) {
    if (_animNode) {
        AnimNode::Pointer node = _animNode->findByName(role);
        if (node) {
            _origRoleAnimations[role] = node;
            const float REFERENCE_FRAMES_PER_SECOND = 30.0f;
            float timeScale = fps / REFERENCE_FRAMES_PER_SECOND;
            auto clipNode = std::make_shared<AnimClip>(role, url, firstFrame, lastFrame, timeScale, loop);
            AnimNode::Pointer parent = node->getParent();
            parent->replaceChild(node, clipNode);
        } else {
            qCWarning(animation) << "Rig::overrideRoleAnimation could not find role " << role;
        }
    } else {
        qCWarning(animation) << "Rig::overrideRoleAnimation avatar not ready yet";
    }
}

void Rig::restoreRoleAnimation(const QString& role) {
    if (_animNode) {
        AnimNode::Pointer node = _animNode->findByName(role);
        if (node) {
            auto iter = _origRoleAnimations.find(role);
            if (iter != _origRoleAnimations.end()) {
                node->getParent()->replaceChild(node, iter->second);
                _origRoleAnimations.erase(iter);
            } else {
                qCWarning(animation) << "Rig::restoreRoleAnimation could not find role " << role;
            }
        }
    } else {
        qCWarning(animation) << "Rig::overrideRoleAnimation avatar not ready yet";
    }
}

void Rig::prefetchAnimation(const QString& url) {

    // This will begin loading the NetworkGeometry for the given URL.
    // which should speed us up if we request it later via overrideAnimation.
    auto clipNode = std::make_shared<AnimClip>("prefetch", url, 0, 0, 1.0, false);
    _prefetchedAnimations.push_back(clipNode);
}

void Rig::destroyAnimGraph() {
    _animSkeleton = nullptr;
    _animLoader = nullptr;
    _animNode = nullptr;
    _relativePoses.clear();
    _absolutePoses.clear();
    _overridePoses.clear();
    _overrideFlags.clear();
}

void Rig::initJointStates(const FBXGeometry& geometry, const glm::mat4& modelOffset) {

    setModelOffset(modelOffset);
    _geometryOffset = AnimPose(geometry.offset);
    _animSkeleton = std::make_shared<AnimSkeleton>(geometry);

    computeEyesInRootFrame(_animSkeleton->getRelativeDefaultPoses());

    _relativePoses.clear();
    _relativePoses = _animSkeleton->getRelativeDefaultPoses();

    buildAbsolutePoses();

    _overridePoses.clear();
    _overridePoses = _animSkeleton->getRelativeDefaultPoses();

    _overrideFlags.clear();
    _overrideFlags.resize(_animSkeleton->getNumJoints(), false);

    _rootJointIndex = geometry.rootJointIndex;
    _leftHandJointIndex = geometry.leftHandJointIndex;
    _leftElbowJointIndex = _leftHandJointIndex >= 0 ? geometry.joints.at(_leftHandJointIndex).parentIndex : -1;
    _leftShoulderJointIndex = _leftElbowJointIndex >= 0 ? geometry.joints.at(_leftElbowJointIndex).parentIndex : -1;
    _rightHandJointIndex = geometry.rightHandJointIndex;
    _rightElbowJointIndex = _rightHandJointIndex >= 0 ? geometry.joints.at(_rightHandJointIndex).parentIndex : -1;
    _rightShoulderJointIndex = _rightElbowJointIndex >= 0 ? geometry.joints.at(_rightElbowJointIndex).parentIndex : -1;
}

void Rig::reset(const FBXGeometry& geometry) {
    _geometryOffset = AnimPose(geometry.offset);
    _animSkeleton = std::make_shared<AnimSkeleton>(geometry);

    computeEyesInRootFrame(_animSkeleton->getRelativeDefaultPoses());

    _relativePoses.clear();
    _relativePoses = _animSkeleton->getRelativeDefaultPoses();

    buildAbsolutePoses();

    _overridePoses.clear();
    _overridePoses = _animSkeleton->getRelativeDefaultPoses();

    _overrideFlags.clear();
    _overrideFlags.resize(_animSkeleton->getNumJoints(), false);

    _rootJointIndex = geometry.rootJointIndex;
    _leftHandJointIndex = geometry.leftHandJointIndex;
    _leftElbowJointIndex = _leftHandJointIndex >= 0 ? geometry.joints.at(_leftHandJointIndex).parentIndex : -1;
    _leftShoulderJointIndex = _leftElbowJointIndex >= 0 ? geometry.joints.at(_leftElbowJointIndex).parentIndex : -1;
    _rightHandJointIndex = geometry.rightHandJointIndex;
    _rightElbowJointIndex = _rightHandJointIndex >= 0 ? geometry.joints.at(_rightHandJointIndex).parentIndex : -1;
    _rightShoulderJointIndex = _rightElbowJointIndex >= 0 ? geometry.joints.at(_rightElbowJointIndex).parentIndex : -1;

    if (!_animGraphURL.isEmpty()) {
        initAnimGraph(_animGraphURL);
    }
}

bool Rig::jointStatesEmpty() {
    return _relativePoses.empty();
}

int Rig::getJointStateCount() const {
    return _relativePoses.size();
}

int Rig::indexOfJoint(const QString& jointName) const {
    return _animSkeleton->nameToJointIndex(jointName);
}

void Rig::setModelOffset(const glm::mat4& modelOffset) {
    _modelOffset = AnimPose(modelOffset);

    // compute geometryToAvatarTransforms
    glm::quat yFlip180 = glm::angleAxis(PI, glm::vec3(0.0f, 1.0f, 0.0f));
    _geometryToRigTransform = AnimPose(glm::vec3(1), yFlip180, glm::vec3()) * _modelOffset * _geometryOffset;
    _rigToGeometryTransform = glm::inverse(_geometryToRigTransform);
}

bool Rig::getJointStateRotation(int index, glm::quat& rotation) const {
    if (index >= 0 && index < (int)_relativePoses.size()) {
        rotation = _relativePoses[index].rot;
        return !isEqual(rotation, _animSkeleton->getRelativeDefaultPose(index).rot);
    } else {
        return false;
    }
}

bool Rig::getJointStateTranslation(int index, glm::vec3& translation) const {
    if (index >= 0 && index < (int)_relativePoses.size()) {
        translation = _relativePoses[index].trans;
        return !isEqual(translation, _animSkeleton->getRelativeDefaultPose(index).trans);
    } else {
        return false;
    }
}

void Rig::clearJointState(int index) {
    if (index >= 0 && index < (int)_relativePoses.size()) {
        _overrideFlags[index] = false;
    }
}

void Rig::clearJointStates() {
    _overrideFlags.clear();
    _overrideFlags.resize(_animSkeleton->getNumJoints());
}

void Rig::clearJointAnimationPriority(int index) {
    if (index >= 0 && index < (int)_overrideFlags.size()) {
        _overrideFlags[index] = false;
    }
}

void Rig::setJointTranslation(int index, bool valid, const glm::vec3& translation, float priority) {
    if (index >= 0 && index < (int)_overrideFlags.size()) {
        if (valid) {
            assert(_overrideFlags.size() == _overridePoses.size());
            _overrideFlags[index] = true;
            _overridePoses[index].trans = translation;
        }
    }
}

void Rig::setJointState(int index, bool valid, const glm::quat& rotation, const glm::vec3& translation, float priority) {
    if (index >= 0 && index < (int)_overrideFlags.size()) {
        assert(_overrideFlags.size() == _overridePoses.size());
        _overrideFlags[index] = true;
        _overridePoses[index].rot = rotation;
        _overridePoses[index].trans = translation;
    }
}

// Deprecated.
// WARNING: this is not symmetric with getJointRotation. It's historical. Use the appropriate specific variation.
void Rig::setJointRotation(int index, bool valid, const glm::quat& rotation, float priority) {
    if (index >= 0 && index < (int)_overrideFlags.size()) {
        if (valid) {
            ASSERT(_overrideFlags.size() == _overridePoses.size());
            _overrideFlags[index] = true;
            _overridePoses[index].rot = rotation;
        }
    }
}

void Rig::restoreJointRotation(int index, float fraction, float priority) {
    // AJT: DEAD CODE?
    ASSERT(false);
}

void Rig::restoreJointTranslation(int index, float fraction, float priority) {
    // AJT: DEAD CODE?
    ASSERT(false);
}

// AJT: NOTE old code did not have 180 flip!
bool Rig::getJointPositionInWorldFrame(int jointIndex, glm::vec3& position, glm::vec3 translation, glm::quat rotation) const {
    if (jointIndex >= 0 && jointIndex < (int)_absolutePoses.size()) {
        glm::quat yFlip180 = glm::angleAxis(PI, glm::vec3(0.0f, 1.0f, 0.0f));
        position = (rotation * yFlip180 * _absolutePoses[jointIndex].trans) + translation;
        return true;
    } else {
        return false;
    }
}

// AJT: NOTE old code did not have 180 flip!
bool Rig::getJointPosition(int jointIndex, glm::vec3& position) const {
    if (jointIndex >= 0 && jointIndex < (int)_absolutePoses.size()) {
        glm::quat yFlip180 = glm::angleAxis(PI, glm::vec3(0.0f, 1.0f, 0.0f));
        position = yFlip180 * _absolutePoses[jointIndex].trans;
        return true;
    } else {
        return false;
    }
}

bool Rig::getJointRotationInWorldFrame(int jointIndex, glm::quat& result, const glm::quat& rotation) const {
    if (jointIndex >= 0 && jointIndex < (int)_absolutePoses.size()) {
        result = rotation * _absolutePoses[jointIndex].rot;
        return true;
    } else {
        return false;
    }
}

// Deprecated.
// WARNING: this is not symmetric with setJointRotation. It's historical. Use the appropriate specific variation.
bool Rig::getJointRotation(int jointIndex, glm::quat& rotation) const {
    if (jointIndex >= 0 && jointIndex < (int)_relativePoses.size()) {
        rotation = _relativePoses[jointIndex].rot;
        return true;
    } else {
        return false;
    }
}

bool Rig::getJointTranslation(int jointIndex, glm::vec3& translation) const {
    if (jointIndex >= 0 && jointIndex < (int)_relativePoses.size()) {
        translation = _relativePoses[jointIndex].trans;
        return true;
    } else {
        return false;
    }
}

bool Rig::getJointCombinedRotation(int jointIndex, glm::quat& result, const glm::quat& rotation) const {
    // AJT: TODO: used by attachments
    ASSERT(false);
    return false;
}

void Rig::calcAnimAlpha(float speed, const std::vector<float>& referenceSpeeds, float* alphaOut) const {

    ASSERT(referenceSpeeds.size() > 0);

    // calculate alpha from linear combination of referenceSpeeds.
    float alpha = 0.0f;
    if (speed <= referenceSpeeds.front()) {
        alpha = 0.0f;
    } else if (speed > referenceSpeeds.back()) {
        alpha = (float)(referenceSpeeds.size() - 1);
    } else {
        for (size_t i = 0; i < referenceSpeeds.size() - 1; i++) {
            if (referenceSpeeds[i] < speed && speed < referenceSpeeds[i + 1]) {
                alpha = (float)i + ((speed - referenceSpeeds[i]) / (referenceSpeeds[i + 1] - referenceSpeeds[i]));
                break;
            }
        }
    }

    *alphaOut = alpha;
}

void Rig::computeEyesInRootFrame(const AnimPoseVec& poses) {
    // TODO: use cached eye/hips indices for these calculations
    int numPoses = poses.size();
    int hipsIndex = _animSkeleton->nameToJointIndex(QString("Hips"));
    int headIndex = _animSkeleton->nameToJointIndex(QString("Head"));
    if (hipsIndex > 0 && headIndex > 0) {
        int rightEyeIndex = _animSkeleton->nameToJointIndex(QString("RightEye"));
        int leftEyeIndex = _animSkeleton->nameToJointIndex(QString("LeftEye"));
        if (numPoses > rightEyeIndex && numPoses > leftEyeIndex && rightEyeIndex > 0 && leftEyeIndex > 0) {
            glm::vec3 rightEye = _animSkeleton->getAbsolutePose(rightEyeIndex, poses).trans;
            glm::vec3 leftEye = _animSkeleton->getAbsolutePose(leftEyeIndex, poses).trans;
            glm::vec3 hips = _animSkeleton->getAbsolutePose(hipsIndex, poses).trans;
            _eyesInRootFrame = 0.5f * (rightEye + leftEye) - hips;
        } else {
            glm::vec3 hips = _animSkeleton->getAbsolutePose(hipsIndex, poses).trans;
            _eyesInRootFrame = 0.5f * (DEFAULT_RIGHT_EYE_POS + DEFAULT_LEFT_EYE_POS) - hips;
        }
    }
}

AnimPose Rig::getAbsoluteDefaultPose(int index) const {
    if (_animSkeleton && index >= 0 && index < _animSkeleton->getNumJoints()) {
        return AnimPose(_geometryToRigTransform) * _animSkeleton->getAbsoluteDefaultPose(index);
    } else {
        return AnimPose::identity;
    }
}

// animation reference speeds.
static const std::vector<float> FORWARD_SPEEDS = { 0.4f, 1.4f, 4.5f }; // m/s
static const std::vector<float> BACKWARD_SPEEDS = { 0.6f, 1.45f }; // m/s
static const std::vector<float> LATERAL_SPEEDS = { 0.2f, 0.65f }; // m/s

void Rig::computeMotionAnimationState(float deltaTime, const glm::vec3& worldPosition, const glm::vec3& worldVelocity, const glm::quat& worldRotation) {

    glm::vec3 front = worldRotation * IDENTITY_FRONT;

    // It can be more accurate/smooth to use velocity rather than position,
    // but some modes (e.g., hmd standing) update position without updating velocity.
    // It's very hard to debug hmd standing. (Look down at yourself, or have a second person observe. HMD third person is a bit undefined...)
    // So, let's create our own workingVelocity from the worldPosition...
    glm::vec3 workingVelocity = _lastVelocity;
    glm::vec3 positionDelta = worldPosition - _lastPosition;

    // Don't trust position delta if deltaTime is 'small'.
    // NOTE: This is mostly just a work around for an issue in oculus 0.7 runtime, where
    // Application::idle() is being called more frequently and with smaller dt's then expected.
    const float SMALL_DELTA_TIME = 0.006f;  // 6 ms
    if (deltaTime > SMALL_DELTA_TIME) {
        workingVelocity = positionDelta / deltaTime;
    }

#if !WANT_DEBUG
    // But for smoothest (non-hmd standing) results, go ahead and use velocity:
    if (!positionDelta.x && !positionDelta.y && !positionDelta.z) {
        workingVelocity = worldVelocity;
    }
#endif

    if (deltaTime > SMALL_DELTA_TIME) {
        _lastVelocity = workingVelocity;
    }

    {
        glm::vec3 localVel = glm::inverse(worldRotation) * workingVelocity;

        float forwardSpeed = glm::dot(localVel, IDENTITY_FRONT);
        float lateralSpeed = glm::dot(localVel, IDENTITY_RIGHT);
        float turningSpeed = glm::orientedAngle(front, _lastFront, IDENTITY_UP) / deltaTime;

        // filter speeds using a simple moving average.
        _averageForwardSpeed.updateAverage(forwardSpeed);
        _averageLateralSpeed.updateAverage(lateralSpeed);

        // sine wave LFO var for testing.
        static float t = 0.0f;
        _animVars.set("sine", 2.0f * static_cast<float>(0.5 * sin(t) + 0.5));

        float moveForwardAlpha = 0.0f;
        float moveBackwardAlpha = 0.0f;
        float moveLateralAlpha = 0.0f;

        // calcuate the animation alpha and timeScale values based on current speeds and animation reference speeds.
        calcAnimAlpha(_averageForwardSpeed.getAverage(), FORWARD_SPEEDS, &moveForwardAlpha);
        calcAnimAlpha(-_averageForwardSpeed.getAverage(), BACKWARD_SPEEDS, &moveBackwardAlpha);
        calcAnimAlpha(fabsf(_averageLateralSpeed.getAverage()), LATERAL_SPEEDS, &moveLateralAlpha);

        _animVars.set("moveForwardSpeed", _averageForwardSpeed.getAverage());
        _animVars.set("moveForwardAlpha", moveForwardAlpha);

        _animVars.set("moveBackwardSpeed", -_averageForwardSpeed.getAverage());
        _animVars.set("moveBackwardAlpha", moveBackwardAlpha);

        _animVars.set("moveLateralSpeed", fabsf(_averageLateralSpeed.getAverage()));
        _animVars.set("moveLateralAlpha", moveLateralAlpha);

        const float MOVE_ENTER_SPEED_THRESHOLD = 0.2f; // m/sec
        const float MOVE_EXIT_SPEED_THRESHOLD = 0.07f;  // m/sec
        const float TURN_ENTER_SPEED_THRESHOLD = 0.5f; // rad/sec
        const float TURN_EXIT_SPEED_THRESHOLD = 0.2f; // rad/sec

        float moveThresh;
        if (_state != RigRole::Move) {
            moveThresh = MOVE_ENTER_SPEED_THRESHOLD;
        } else {
            moveThresh = MOVE_EXIT_SPEED_THRESHOLD;
        }

        float turnThresh;
        if (_state != RigRole::Turn) {
            turnThresh = TURN_ENTER_SPEED_THRESHOLD;
        } else {
            turnThresh = TURN_EXIT_SPEED_THRESHOLD;
        }

        if (glm::length(localVel) > moveThresh) {
            if (_desiredState != RigRole::Move) {
                _desiredStateAge = 0.0f;
            }
            _desiredState = RigRole::Move;
        } else {
            if (fabsf(turningSpeed) > turnThresh) {
                if (_desiredState != RigRole::Turn) {
                    _desiredStateAge = 0.0f;
                }
                _desiredState = RigRole::Turn;
            } else { // idle
                if (_desiredState != RigRole::Idle) {
                    _desiredStateAge = 0.0f;
                }
                _desiredState = RigRole::Idle;
            }
        }

        const float STATE_CHANGE_HYSTERESIS_TIMER = 0.1f;

        if ((_desiredStateAge >= STATE_CHANGE_HYSTERESIS_TIMER) && _desiredState != _state) {
            _state = _desiredState;
            _desiredStateAge = 0.0f;
        }

        _desiredStateAge += deltaTime;

        if (_state == RigRole::Move) {
            if (glm::length(localVel) > MOVE_ENTER_SPEED_THRESHOLD) {
                if (fabsf(forwardSpeed) > 0.5f * fabsf(lateralSpeed)) {
                    if (forwardSpeed > 0.0f) {
                        // forward
                        _animVars.set("isMovingForward", true);
                        _animVars.set("isMovingBackward", false);
                        _animVars.set("isMovingRight", false);
                        _animVars.set("isMovingLeft", false);
                        _animVars.set("isNotMoving", false);

                    } else {
                        // backward
                        _animVars.set("isMovingBackward", true);
                        _animVars.set("isMovingForward", false);
                        _animVars.set("isMovingRight", false);
                        _animVars.set("isMovingLeft", false);
                        _animVars.set("isNotMoving", false);
                    }
                } else {
                    if (lateralSpeed > 0.0f) {
                        // right
                        _animVars.set("isMovingRight", true);
                        _animVars.set("isMovingLeft", false);
                        _animVars.set("isMovingForward", false);
                        _animVars.set("isMovingBackward", false);
                        _animVars.set("isNotMoving", false);
                    } else {
                        // left
                        _animVars.set("isMovingLeft", true);
                        _animVars.set("isMovingRight", false);
                        _animVars.set("isMovingForward", false);
                        _animVars.set("isMovingBackward", false);
                        _animVars.set("isNotMoving", false);
                    }
                }
                _animVars.set("isTurningLeft", false);
                _animVars.set("isTurningRight", false);
                _animVars.set("isNotTurning", true);
            }
        } else if (_state == RigRole::Turn) {
            if (turningSpeed > 0.0f) {
                // turning right
                _animVars.set("isTurningRight", true);
                _animVars.set("isTurningLeft", false);
                _animVars.set("isNotTurning", false);
            } else {
                // turning left
                _animVars.set("isTurningLeft", true);
                _animVars.set("isTurningRight", false);
                _animVars.set("isNotTurning", false);
            }
            _animVars.set("isMovingForward", false);
            _animVars.set("isMovingBackward", false);
            _animVars.set("isMovingRight", false);
            _animVars.set("isMovingLeft", false);
            _animVars.set("isNotMoving", true);
        } else {
            // default anim vars to notMoving and notTurning
            _animVars.set("isMovingForward", false);
            _animVars.set("isMovingBackward", false);
            _animVars.set("isMovingLeft", false);
            _animVars.set("isMovingRight", false);
            _animVars.set("isNotMoving", true);
            _animVars.set("isTurningLeft", false);
            _animVars.set("isTurningRight", false);
            _animVars.set("isNotTurning", true);
        }

        t += deltaTime;
    }

    _lastFront = front;
    _lastPosition = worldPosition;
}

// Allow script to add/remove handlers and report results, from within their thread.
QScriptValue Rig::addAnimationStateHandler(QScriptValue handler, QScriptValue propertiesList) { // called in script thread
    QMutexLocker locker(&_stateMutex);
    // Find a safe id, even if there are lots of many scripts add and remove handlers repeatedly.
    while (!_nextStateHandlerId || _stateHandlers.contains(_nextStateHandlerId)) { // 0 is unused, and don't reuse existing after wrap.
      _nextStateHandlerId++;
    }
    StateHandler& data = _stateHandlers[_nextStateHandlerId];
    data.function = handler;
    data.useNames = propertiesList.isArray();
    if (data.useNames) {
        data.propertyNames = propertiesList.toVariant().toStringList();
    }
    return QScriptValue(_nextStateHandlerId); // suitable for giving to removeAnimationStateHandler
}
void Rig::removeAnimationStateHandler(QScriptValue identifier) { // called in script thread
    QMutexLocker locker(&_stateMutex);
    _stateHandlers.remove(identifier.isNumber() ? identifier.toInt32() : 0); // silently continues if handler not present. 0 is unused
}
void Rig::animationStateHandlerResult(int identifier, QScriptValue result) { // called synchronously from script
    QMutexLocker locker(&_stateMutex);
    auto found = _stateHandlers.find(identifier);
    if (found == _stateHandlers.end()) {
        return; // Don't use late-breaking results that got reported after the handler was removed.
    }
    found.value().results.animVariantMapFromScriptValue(result); // Into our own copy.
}

void Rig::updateAnimationStateHandlers() { // called on avatar update thread (which may be main thread)
    QMutexLocker locker(&_stateMutex);
    // It might pay to produce just one AnimVariantMap copy here, with a union of all the requested propertyNames,
    // rather than having each callAnimationStateHandler invocation make its own copy.
    // However, that copying is done on the script's own time rather than ours, so even if it's less cpu, it would be more
    // work on the avatar update thread (which is possibly the main thread).
    for (auto data = _stateHandlers.begin(); data != _stateHandlers.end(); data++) {
        // call out:
        int identifier = data.key();
        StateHandler& value = data.value();
        QScriptValue& function = value.function;
        auto handleResult = [this, identifier](QScriptValue result) { // called in script thread to get the result back to us.
            animationStateHandlerResult(identifier, result);
        };
        // invokeMethod makes a copy of the args, and copies of AnimVariantMap do copy the underlying map, so this will correctly capture
        // the state of _animVars and allow continued changes to _animVars in this thread without conflict.
        QMetaObject::invokeMethod(function.engine(), "callAnimationStateHandler",  Qt::QueuedConnection,
                                  Q_ARG(QScriptValue, function),
                                  Q_ARG(AnimVariantMap, _animVars),
                                  Q_ARG(QStringList, value.propertyNames),
                                  Q_ARG(bool, value.useNames),
                                  Q_ARG(AnimVariantResultHandler, handleResult));
        // It turns out that, for thread-safety reasons, ScriptEngine::callAnimationStateHandler will invoke itself if called from other
        // than the script thread. Thus the above _could_ be replaced with an ordinary call, which will then trigger the same
        // invokeMethod as is done explicitly above. However, the script-engine library depends on this animation library, not vice versa.
        // We could create an AnimVariantCallingMixin class in shared, with an abstract virtual slot
        // AnimVariantCallingMixin::callAnimationStateHandler (and move AnimVariantMap/AnimVaraintResultHandler to shared), but the
        // call site here would look like this instead of the above:
        //   dynamic_cast<AnimVariantCallingMixin*>(function.engine())->callAnimationStateHandler(function, ..., handleResult);
        // This works (I tried it), but the result would be that we would still have same runtime type checks as the invokeMethod above
        // (occuring within the ScriptEngine::callAnimationStateHandler invokeMethod trampoline), _plus_ another runtime check for the dynamic_cast.

        // gather results in (likely from an earlier update):
        _animVars.copyVariantsFrom(value.results); // If multiple handlers write the same anim var, the last registgered wins. (_map preserves order).
    }
}

void Rig::updateAnimations(float deltaTime, glm::mat4 rootTransform) {

    setModelOffset(rootTransform);

    if (_animNode) {

        updateAnimationStateHandlers();
        _animVars.setRigToGeometryTransform(_rigToGeometryTransform);

        // evaluate the animation
        AnimNode::Triggers triggersOut;
        _relativePoses = _animNode->evaluate(_animVars, deltaTime, triggersOut);
        if ((int)_relativePoses.size() != _animSkeleton->getNumJoints()) {
            // animations haven't fully loaded yet.
            _relativePoses = _animSkeleton->getRelativeDefaultPoses();
        }
        _animVars.clearTriggers();
        for (auto& trigger : triggersOut) {
            _animVars.setTrigger(trigger);
        }

        computeEyesInRootFrame(_relativePoses);
    }

    applyOverridePoses();
    buildAbsolutePoses();
}

void Rig::inverseKinematics(int endIndex, glm::vec3 targetPosition, const glm::quat& targetRotation, float priority,
                            const QVector<int>& freeLineage, glm::mat4 rootTransform) {
    ASSERT(false);
}

bool Rig::restoreJointPosition(int jointIndex, float fraction, float priority, const QVector<int>& freeLineage) {
    ASSERT(false);
    return false;
}

float Rig::getLimbLength(int jointIndex, const QVector<int>& freeLineage,
                         const glm::vec3 scale, const QVector<FBXJoint>& fbxJoints) const {
    ASSERT(false);
    return 1.0f;
}

glm::quat Rig::setJointRotationInBindFrame(int jointIndex, const glm::quat& rotation, float priority) {
    ASSERT(false);
    return glm::quat();
}

glm::vec3 Rig::getJointDefaultTranslationInConstrainedFrame(int jointIndex) {
    ASSERT(false);
    return glm::vec3();
}

glm::quat Rig::setJointRotationInConstrainedFrame(int jointIndex, glm::quat targetRotation, float priority, float mix) {
    ASSERT(false);
    return glm::quat();
}

bool Rig::getJointRotationInConstrainedFrame(int jointIndex, glm::quat& quatOut) const {
    ASSERT(false);
    return false;
}

void Rig::clearJointStatePriorities() {
    ASSERT(false);
}

glm::quat Rig::getJointDefaultRotationInParentFrame(int jointIndex) {
    ASSERT(false);
    return glm::quat();
}

void Rig::updateFromHeadParameters(const HeadParameters& params, float dt) {
    if (params.enableLean) {
        updateLeanJoint(params.leanJointIndex, params.leanSideways, params.leanForward, params.torsoTwist);
    } else {
        _animVars.unset("lean");
    }
    updateNeckJoint(params.neckJointIndex, params);

    _animVars.set("isTalking", params.isTalking);
    _animVars.set("notIsTalking", !params.isTalking);
}

void Rig::updateFromEyeParameters(const EyeParameters& params) {
    updateEyeJoint(params.leftEyeJointIndex, params.modelTranslation, params.modelRotation,
                   params.worldHeadOrientation, params.eyeLookAt, params.eyeSaccade);
    updateEyeJoint(params.rightEyeJointIndex, params.modelTranslation, params.modelRotation,
                   params.worldHeadOrientation, params.eyeLookAt, params.eyeSaccade);
}

static const glm::vec3 X_AXIS(1.0f, 0.0f, 0.0f);
static const glm::vec3 Y_AXIS(0.0f, 1.0f, 0.0f);
static const glm::vec3 Z_AXIS(0.0f, 0.0f, 1.0f);

void Rig::updateLeanJoint(int index, float leanSideways, float leanForward, float torsoTwist) {
    if (index >= 0 && index) {
        if (_animSkeleton) {
            glm::quat absRot = (glm::angleAxis(-RADIANS_PER_DEGREE * leanSideways, Z_AXIS) *
                                glm::angleAxis(-RADIANS_PER_DEGREE * leanForward, X_AXIS) *
                                glm::angleAxis(RADIANS_PER_DEGREE * torsoTwist, Y_AXIS));
            _animVars.set("lean", absRot);
        }
    }
}

void Rig::computeHeadNeckAnimVars(const AnimPose& hmdPose, glm::vec3& headPositionOut, glm::quat& headOrientationOut,
                                  glm::vec3& neckPositionOut, glm::quat& neckOrientationOut) const {

    // the input hmd values are in avatar/rig space
    const glm::vec3 hmdPosition = hmdPose.trans;
    const glm::quat hmdOrientation = hmdPose.rot;

    // TODO: cache jointIndices
    int rightEyeIndex = indexOfJoint("RightEye");
    int leftEyeIndex = indexOfJoint("LeftEye");
    int headIndex = indexOfJoint("Head");
    int neckIndex = indexOfJoint("Neck");

    glm::vec3 absRightEyePos = rightEyeIndex != -1 ? getAbsoluteDefaultPose(rightEyeIndex).trans : DEFAULT_RIGHT_EYE_POS;
    glm::vec3 absLeftEyePos = leftEyeIndex != -1 ? getAbsoluteDefaultPose(leftEyeIndex).trans : DEFAULT_LEFT_EYE_POS;
    glm::vec3 absHeadPos = headIndex != -1 ? getAbsoluteDefaultPose(headIndex).trans : DEFAULT_HEAD_POS;
    glm::vec3 absNeckPos = neckIndex != -1 ? getAbsoluteDefaultPose(neckIndex).trans : DEFAULT_NECK_POS;

    glm::vec3 absCenterEyePos = (absRightEyePos + absLeftEyePos) / 2.0f;
    glm::vec3 eyeOffset = absCenterEyePos - absHeadPos;
    glm::vec3 headOffset = absHeadPos - absNeckPos;

    // apply simplistic head/neck model

    // head
    headPositionOut = hmdPosition - hmdOrientation * eyeOffset;
    headOrientationOut = hmdOrientation;

    // neck
    neckPositionOut = hmdPosition - hmdOrientation * (headOffset + eyeOffset);

    // slerp between default orientation and hmdOrientation
    neckOrientationOut = safeMix(hmdOrientation, _animSkeleton->getRelativeDefaultPose(neckIndex).rot, 0.5f);
}

void Rig::updateNeckJoint(int index, const HeadParameters& params) {
    if (_animSkeleton && index >= 0 && index < _animSkeleton->getNumJoints()) {
        glm::quat yFlip180 = glm::angleAxis(PI, glm::vec3(0.0f, 1.0f, 0.0f));
        if (params.isInHMD) {
            glm::vec3 headPos, neckPos;
            glm::quat headRot, neckRot;

            AnimPose hmdPose(glm::vec3(1.0f), params.localHeadOrientation * yFlip180, params.localHeadPosition);
            computeHeadNeckAnimVars(hmdPose, headPos, headRot, neckPos, neckRot);

            // debug rendering
#ifdef DEBUG_RENDERING
            const glm::vec4 red(1.0f, 0.0f, 0.0f, 1.0f);
            const glm::vec4 green(0.0f, 1.0f, 0.0f, 1.0f);

            // transform from bone into avatar space
            AnimPose headPose(glm::vec3(1), headRot, headPos);
            DebugDraw::getInstance().addMyAvatarMarker("headTarget", headPose.rot, headPose.trans, red);

            // transform from bone into avatar space
            AnimPose neckPose(glm::vec3(1), neckRot, neckPos);
            DebugDraw::getInstance().addMyAvatarMarker("neckTarget", neckPose.rot, neckPose.trans, green);
#endif

            _animVars.set("headPosition", headPos);
            _animVars.set("headRotation", headRot);
            _animVars.set("headType", (int)IKTarget::Type::HmdHead);
            _animVars.set("neckPosition", neckPos);
            _animVars.set("neckRotation", neckRot);
            _animVars.set("neckType", (int)IKTarget::Type::Unknown); // 'Unknown' disables the target

        } else {
            _animVars.unset("headPosition");
            _animVars.set("headRotation", params.localHeadOrientation * yFlip180);
            _animVars.set("headAndNeckType", (int)IKTarget::Type::RotationOnly);
            _animVars.set("headType", (int)IKTarget::Type::RotationOnly);
            _animVars.unset("neckPosition");
            _animVars.unset("neckRotation");
            _animVars.set("neckType", (int)IKTarget::Type::RotationOnly);
        }
    }
}

void Rig::updateEyeJoint(int index, const glm::vec3& modelTranslation, const glm::quat& modelRotation, const glm::quat& worldHeadOrientation, const glm::vec3& lookAtSpot, const glm::vec3& saccade) {
    // AJT: TODO: fix eye tracking!
    /*
    {
        if (index >= 0 && _jointStates[index].getParentIndex() >= 0) {
            auto& state = _jointStates[index];
            auto& parentState = _jointStates[state.getParentIndex()];

            // NOTE: at the moment we do the math in the world-frame, hence the inverse transform is more complex than usual.
            glm::mat4 inverse = glm::inverse(glm::mat4_cast(modelRotation) * parentState.getTransform() *
                                             glm::translate(state.getDefaultTranslationInConstrainedFrame()) *
                                             state.getPreTransform() * glm::mat4_cast(state.getPreRotation() * state.getDefaultRotation()));
            glm::vec3 front = glm::vec3(inverse * glm::vec4(worldHeadOrientation * IDENTITY_FRONT, 0.0f));
            glm::vec3 lookAtDelta = lookAtSpot - modelTranslation;
            glm::vec3 lookAt = glm::vec3(inverse * glm::vec4(lookAtDelta + glm::length(lookAtDelta) * saccade, 1.0f));
            glm::quat between = rotationBetween(front, lookAt);
            const float MAX_ANGLE = 30.0f * RADIANS_PER_DEGREE;
            state.setRotationInConstrainedFrame(glm::angleAxis(glm::clamp(glm::angle(between), -MAX_ANGLE, MAX_ANGLE), glm::axis(between)) *
                                                state.getDefaultRotation(), DEFAULT_PRIORITY);
        }
    }
    */
}

void Rig::updateFromHandParameters(const HandParameters& params, float dt) {

    if (_animSkeleton && _animNode) {
        if (params.isLeftEnabled) {
            _animVars.set("leftHandPosition", params.leftPosition);
            _animVars.set("leftHandRotation", params.leftOrientation);
            _animVars.set("leftHandType", (int)IKTarget::Type::RotationAndPosition);
        } else {
            _animVars.unset("leftHandPosition");
            _animVars.unset("leftHandRotation");
            _animVars.set("leftHandType", (int)IKTarget::Type::HipsRelativeRotationAndPosition);
        }
        if (params.isRightEnabled) {
            _animVars.set("rightHandPosition", params.rightPosition);
            _animVars.set("rightHandRotation", params.rightOrientation);
            _animVars.set("rightHandType", (int)IKTarget::Type::RotationAndPosition);
        } else {
            _animVars.unset("rightHandPosition");
            _animVars.unset("rightHandRotation");
            _animVars.set("rightHandType", (int)IKTarget::Type::HipsRelativeRotationAndPosition);
        }

        // set leftHand grab vars
        _animVars.set("isLeftHandIdle", false);
        _animVars.set("isLeftHandPoint", false);
        _animVars.set("isLeftHandGrab", false);

        // Split the trigger range into three zones.
        bool rampOut = false;
        if (params.leftTrigger > 0.6666f) {
            _animVars.set("isLeftHandGrab", true);
        } else if (params.leftTrigger > 0.3333f) {
            _animVars.set("isLeftHandPoint", true);
        } else {
            _animVars.set("isLeftHandIdle", true);
            rampOut = true;
        }
        const float OVERLAY_RAMP_OUT_SPEED = 6.0f;  // ramp in and out over 1/6th of a sec
        _leftHandOverlayAlpha = glm::clamp(_leftHandOverlayAlpha + (rampOut ? -1.0f : 1.0f) * OVERLAY_RAMP_OUT_SPEED * dt, 0.0f, 1.0f);
        _animVars.set("leftHandOverlayAlpha", _leftHandOverlayAlpha);
        _animVars.set("leftHandGrabBlend", params.leftTrigger);

        // set leftHand grab vars
        _animVars.set("isRightHandIdle", false);
        _animVars.set("isRightHandPoint", false);
        _animVars.set("isRightHandGrab", false);

        // Split the trigger range into three zones
        rampOut = false;
        if (params.rightTrigger > 0.6666f) {
            _animVars.set("isRightHandGrab", true);
        } else if (params.rightTrigger > 0.3333f) {
            _animVars.set("isRightHandPoint", true);
        } else {
            _animVars.set("isRightHandIdle", true);
            rampOut = true;
        }
        _rightHandOverlayAlpha = glm::clamp(_rightHandOverlayAlpha + (rampOut ? -1.0f : 1.0f) * OVERLAY_RAMP_OUT_SPEED * dt, 0.0f, 1.0f);
        _animVars.set("rightHandOverlayAlpha", _rightHandOverlayAlpha);
        _animVars.set("rightHandGrabBlend", params.rightTrigger);
    }
}

void Rig::initAnimGraph(const QUrl& url) {
    _animGraphURL = url;

    _animNode.reset();

    // load the anim graph
    _animLoader.reset(new AnimNodeLoader(url));
    connect(_animLoader.get(), &AnimNodeLoader::success, [this](AnimNode::Pointer nodeIn) {
        _animNode = nodeIn;
        _animNode->setSkeleton(_animSkeleton);
    });
    connect(_animLoader.get(), &AnimNodeLoader::error, [url](int error, QString str) {
        qCCritical(animation) << "Error loading" << url.toDisplayString() << "code = " << error << "str =" << str;
    });
}

bool Rig::getModelRegistrationPoint(glm::vec3& modelRegistrationPointOut) const {
    if (_animSkeleton && _rootJointIndex >= 0) {
        modelRegistrationPointOut = _geometryOffset * -_animSkeleton->getAbsoluteDefaultPose(_rootJointIndex).trans;
        return true;
    } else {
        return false;
    }
}

void Rig::applyOverridePoses() {
    if (!_animSkeleton) {
        return;
    }

    ASSERT(_animSkeleton->getNumJoints() == (int)_relativePoses.size());
    ASSERT(_animSkeleton->getNumJoints() == (int)_overrideFlags.size());
    ASSERT(_animSkeleton->getNumJoints() == (int)_overridePoses.size());

    for (size_t i = 0; i < _overrideFlags.size(); i++) {
        if (_overrideFlags[i]) {
            _relativePoses[i] = _overridePoses[i];
        }
    }
}

void Rig::buildAbsolutePoses() {
    if (!_animSkeleton) {
        return;
    }

    ASSERT(_animSkeleton->getNumJoints() == (int)_relativePoses.size());

    _absolutePoses.resize(_relativePoses.size());
    for (int i = 0; i < (int)_relativePoses.size(); i++) {
        int parentIndex = _animSkeleton->getParentIndex(i);
        if (parentIndex == -1) {
            _absolutePoses[i] = _relativePoses[i];
        } else {
            _absolutePoses[i] = _absolutePoses[parentIndex] * _relativePoses[i];
        }
    }

    AnimPose rootTransform(_modelOffset * _geometryOffset);
    for (int i = 0; i < (int)_absolutePoses.size(); i++) {
        _absolutePoses[i] = rootTransform * _absolutePoses[i];
    }
}

glm::mat4 Rig::getJointTransform(int jointIndex) const {
    if (jointIndex >= 0 && jointIndex < (int)_absolutePoses.size()) {
        return _absolutePoses[jointIndex];
    } else {
        return glm::mat4();
    }
}

void Rig::copyJointsIntoJointData(QVector<JointData>& jointDataVec) const {
    jointDataVec.resize(getJointStateCount());
    for (int i = 0; i < jointDataVec.size(); i++) {
        JointData& data = jointDataVec[i];
        data.rotationSet |= getJointStateRotation(i, data.rotation);
        // geometry offset is used here so that translations are in meters.
        // this is what the avatar mixer expects
        data.translationSet |= getJointStateTranslation(i, data.translation);
        data.translation = _geometryOffset * data.translation;
    }
}

void Rig::copyJointsFromJointData(const QVector<JointData>& jointDataVec) {
    AnimPose invGeometryOffset = _geometryOffset.inverse();
    for (int i = 0; i < jointDataVec.size(); i++) {
        const JointData& data = jointDataVec.at(i);
        setJointRotation(i, data.rotationSet, data.rotation, 1.0f);
        // geometry offset is used here to undo the fact that avatar mixer translations are in meters.
        setJointTranslation(i, data.translationSet, invGeometryOffset * data.translation, 1.0f);
    }
}

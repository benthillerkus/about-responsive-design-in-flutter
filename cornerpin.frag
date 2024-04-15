// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform sampler2D uTexture;
uniform sampler2D uUVMap;

out vec4 fragColor;

void main() {
  vec4 uvLookup = texture(uUVMap, FlutterFragCoord().xy / uSize);
  fragColor = uvLookup.z > 0.0 ? vec4(0.0, 0.0, 0.0, 0.0) : texture(uTexture, uvLookup.xy);
}

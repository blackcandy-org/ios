#!/bin/bash


ENV_VARS=("APP_IDENTIFIER")

# Set environment variables for project build configuration
for var in "${ENV_VARS[@]}"; do
  echo "${var}=${!var}" >> BlackCandy.xcconfig
done

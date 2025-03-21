#!/bin/sh

imagename=~/Downloads/Felis_silvestris_silvestris_small_gradual_decrease_of_quality.png

export ENV_IMAGE_NAME="${imagename}"

run_b(){
  ./ImageMetadata |
    bat --language=yaml
}

which bat | fgrep -q bat || exec ./ImageMetadata

run_b

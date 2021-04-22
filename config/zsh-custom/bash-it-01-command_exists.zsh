#!/usr/bin/env bash

function _command_exists ()
{
  type "$1" &> /dev/null ;
}

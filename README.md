RubySlippers Build Environment
==============================

## A solid build environment is key

I am a ruby head. I love gems. I love Rails and Sinatra and like here, pure Rack apps. I love testing. I HATE bugs. Yep, I fucking hate em. They make my sunny day turn to shit.

On that note you may better understand why I have the system set up this way. This is the BuildEnv, this is what I open in Textmate when I am working on RubySlippers.

This project hosts:

  * base - This is the ruby slippers front end as a pure rack app
  * engine - The ruby slippers engine gem
  * deploy - This is where the app is deployed to to run the integration tests
  

## To Setup the project on your machine AND use my cool build shit

To start off, in this directory, run:

    git clone git@github.com:dreamr/ruby-slippers.git base
    git clone git@github.com:dreamr/ruby-slippers-engine.git engine
    mkdir deploy
    
To run your tests, in this directory, run:

    
  
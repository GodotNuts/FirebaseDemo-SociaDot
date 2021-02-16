extends Node

signal loading()
signal show_error()

var signin_scene : PackedScene = preload("res://main/scn/signin/signin.tscn")
var home_scene : PackedScene = preload("res://main/scn/home/home.tscn")

var post_container_scene : PackedScene = preload("res://main/scn/post/post.tscn")
var chat_node_scene : PackedScene = preload("res://main/scn/chat_node/chat_node.tscn")

# Particles
var love_particle_scene : PackedScene = preload("res://main/scn/particles/love_particle/love_particle.tscn")
var connect_particle_scene : PackedScene = preload("res://main/scn/particles/connect_particle/connect_particle.tscn")

var signin : Control
var home : Control

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

func loading(l : bool):
    emit_signal("loading", l)

func show_error(error : String):
    emit_signal("show_error", error)

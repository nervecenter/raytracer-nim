# raytracer.nim
# by Chris Collazo
# A practice Nim translation of Ray Tracing in One Weekend
# by Peter Shirley (https://raytracing.github.io/books/RayTracingInOneWeekend.html)

import system/io
import std/strformat
import std/terminal
import std/os
import std/strutils
import std/math

type Vec3 = object
    x, y, z: float64

type Point3 = Vec3

type Color = Vec3

type Ray = object
    origin: Point3
    direction: Vec3


proc `+`(u: ref Vec3, v: Vec3): ref Vec3 =
    u.x += v.x
    u.y += v.y
    u.z += v.z
    u

proc `*`(u: ref Vec3, v: Vec3): ref Vec3 =
    u.x *= v.x
    u.y *= v.y
    u.z *= v.z
    u

proc `/`(u: ref Vec3, t: float64): ref Vec3 =
    u.x /= t
    u.y /= t
    u.z /= t
    u

proc length_squared(v: Vec3): float64 =
    v.x^2 + v.y^2 + v.z^2

proc length(v: Vec3): float64 =
    v.length_squared.sqrt

proc `+`(u: Vec3, v: Vec3): Vec3 =
    Vec3(x: u.x + v.x, y: u.y + v.y, z: u.z + v.z)

proc `-`(u: Vec3, v: Vec3): Vec3 =
    Vec3(x: u.x - v.x, y: u.y - v.y, z: u.z - v.z)

proc `*`(u: Vec3, v: Vec3): Vec3 =
    Vec3(x: u.x * v.x, y: u.y * v.y, z: u.z * v.z)

proc `*`(t: float64, v: Vec3): Vec3 =
    Vec3(x: v.x * t, y: v.y * t, z: v.z * t)

proc `*`(v: Vec3, t: float64): Vec3 =
    t * v

proc `/`(v: Vec3, t: float64): Vec3 =
    (1/t) * v

proc dot(u: Vec3, v: Vec3): float64 =
    u.x * v.x + u.y * v.y + u.z * v.z

proc cross(u: Vec3, v: Vec3): Vec3 =
    Vec3(
        x: u.y * v.z - u.z * v.y,
        y: u.z * v.x - u.x * v.z,
        z: u.x * v.y - u.y - v.x
    )

proc unit_vector(v: Vec3): Vec3 =
    v / v.length

proc at(r: Ray, t: float64): Point3 =
    return r.origin + (t * r.direction)

proc write_color(out_file: var File, pixel_color: Color) =
    let
        out_r = uint8(255.999 * pixel_color.x)
        out_g = uint8(255.999 * pixel_color.y)
        out_b = uint8(255.999 * pixel_color.z)
    out_file.write(&"{out_r} {out_g} {out_b}\n")

proc hit_sphere(center: Point3, radius: float64, r: Ray): float64 =
    let
        oc = r.origin - center
        a = r.direction.length_squared
        half_b = dot(oc, r.direction)
        c = oc.length_squared - radius^2
        discriminant = half_b^2 - a * c
    if discriminant < 0:
        -1.0
    else:
        (-half_b - sqrt(discriminant)) / a

proc ray_color(r: Ray): Color =
    var t = hit_sphere(Point3(x: 0.0, y: 0.0, z: -1.0), 0.5, r)
    if t > 0.0:
        let N = unit_vector(r.at(t) - Vec3(x: 0.0, y: 0.0, z: -1.0))
        return 0.5 * Color(x: N.x + 1, y: N.y + 1, z: N.z + 1)

    let unit_direction = r.direction.unit_vector
    t = 0.5 * (unit_direction.y + 1.0)
    (1.0 - t) * Color(x: 1.0, y: 1.0, z: 1.0) +
        (t * Color(x: 0.5, y: 0.7, z: 1.0))

proc color_swatch() =
    let
        image_width = 256
        image_height = 256

    var ppm_file = open("color_swatch.ppm", fmWrite)
    ppm_file.write(&"P3\n{image_width} {image_height}\n255\n")

    for j in countdown(image_height - 1, 0, 1):

        stdout.write(&"\rScanlines remaining: {j} \n")
        cursorUp 1
        eraseLine()

        for i in 0..<image_width:

            let pixel_color = Color(
                x: float64(i) / float64(image_width - 1),
                y: float64(j) / float64(image_height - 1),
                z: 0.25
            )
            ppm_file.write_color(pixel_color)

    echo "Done."


proc blue_sky() =
    let
        aspect_ratio = 16.0 / 9.0
        image_width = 400
        image_height = int(float(image_width) / aspect_ratio)

        viewport_height = 2.0
        viewport_width = aspect_ratio * viewport_height
        focal_length = 1.0

        origin = Point3(x: 0.0, y: 0.0, z: 0.0)
        horizontal = Vec3(x: viewport_width, y: 0.0, z: 0.0)
        vertical = Vec3(x: 0.0, y: viewport_height, z: 0.0)
        lower_left_corner = origin - (horizontal / 2) -
            (vertical / 2) - Vec3(x: 0.0, y: 0.0, z: focal_length)

    var ppm_file = open("blue_sky.ppm", fmWrite)
    ppm_file.write(&"P3\n{image_width} {image_height}\n255\n")

    for j in countdown(image_height - 1, 0, 1):

        stdout.write(&"\rScanlines remaining: {j} \n")
        cursorUp 1
        eraseLine()

        for i in 0..<image_width:

            let
                u = float64(i) / float64(image_width - 1)
                v = float64(j) / float64(image_height - 1)
                r = Ray(
                    origin: origin,
                    direction: lower_left_corner + (u * horizontal) +
                        (v * vertical) - origin
                )
                pixel_color = r.ray_color

            ppm_file.write_color(pixel_color)

    echo "Done."


let
    usage = "Usage: ./raytracer [colorswatch|bluesky]"
    params = commandLineParams()

if len(params) != 1:
    echo usage
else:
    let command = params[0]

    if command == "colorswatch":
        color_swatch()
    elif command == "bluesky":
        blue_sky()
    else:
        echo usage

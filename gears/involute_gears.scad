// Parametric Involute Bevel and Spur Gears by GregFrost
// It is licensed under the Creative Commons - GNU LGPL 2.1 license.
// © 2010 by GregFrost, thingiverse.com/Amp
// http://www.thingiverse.com/thing:3575 and http://www.thingiverse.com/thing:3752

use <MCAD/general/utilities.scad>

// Simple Test:
gear (
	number_of_teeth = 30,
	circular_pitch=700,
	gear_thickness = 12,
	rim_thickness = 15,
	hub_thickness = 17,
	circles=8,
	roundsize = 0
	);

translate ([700 * PI / 180 * 30 / 2 / PI * 2,0,0])
rotate (180 + 360 / 30 / 2)
gear (
	number_of_teeth = 30,
	circular_pitch=700,
	gear_thickness = 12,
	rim_thickness = 15,
	hub_thickness = 17,
	circles=8,
	roundsize = 1
	);

//Complex Spur Gear Test:
//test_gears ();

// Meshing Double Helix:
//test_meshing_double_helix ();

module test_meshing_double_helix(){
    meshing_double_helix ();
}

// Demonstrate the backlash option for Spur gears.
//test_backlash ();

// Demonstrate how to make meshing bevel gears.
//test_bevel_gear_pair();

module test_bevel_gear_pair(){
    bevel_gear_pair ();
}

module test_bevel_gear(){bevel_gear();}

//bevel_gear();

pi=3.1415926535897932384626433832795;

//==================================================
// Bevel Gears:
// Two gears with the same cone distance, circular pitch (measured at the cone distance)
// and pressure angle will mesh.

module bevel_gear_pair (
	gear1_teeth = 41,
	gear2_teeth = 7,
	axis_angle = 90,
	outside_circular_pitch=1000)
{
	outside_pitch_radius1 = gear1_teeth * outside_circular_pitch / 360;
	outside_pitch_radius2 = gear2_teeth * outside_circular_pitch / 360;
	pitch_apex1=outside_pitch_radius2 * sin (axis_angle) +
		(outside_pitch_radius2 * cos (axis_angle) + outside_pitch_radius1) / tan (axis_angle);
	cone_distance = sqrt (pow (pitch_apex1, 2) + pow (outside_pitch_radius1, 2));
	pitch_apex2 = sqrt (pow (cone_distance, 2) - pow (outside_pitch_radius2, 2));
	echo ("cone_distance", cone_distance);
	pitch_angle1 = asin (outside_pitch_radius1 / cone_distance);
	pitch_angle2 = asin (outside_pitch_radius2 / cone_distance);
	echo ("pitch_angle1, pitch_angle2", pitch_angle1, pitch_angle2);
	echo ("pitch_angle1 + pitch_angle2", pitch_angle1 + pitch_angle2);

	rotate([0,0,90])
	translate ([0,0,pitch_apex1+20])
	{
		translate([0,0,-pitch_apex1])
		bevel_gear (
			number_of_teeth=gear1_teeth,
			cone_distance=cone_distance,
			pressure_angle=30,
			outside_circular_pitch=outside_circular_pitch);

		rotate([0,-(pitch_angle1+pitch_angle2),0])
		translate([0,0,-pitch_apex2])
		bevel_gear (
			number_of_teeth=gear2_teeth,
			cone_distance=cone_distance,
			pressure_angle=30,
			outside_circular_pitch=outside_circular_pitch);
	}
}

//Bevel Gear Finishing Options:
bevel_gear_flat = 0;
bevel_gear_back_cone = 1;

module bevel_gear (
	number_of_teeth=11,
	cone_distance=100,
	face_width=20,
	outside_circular_pitch=1000,
	pressure_angle=30,
	clearance = 0.2,
	bore_diameter=5,
	gear_thickness = 15,
	backlash = 0,
	involute_facets=0,
	finish = -1)
{
	echo ("bevel_gear",
		"teeth", number_of_teeth,
		"cone distance", cone_distance,
		face_width,
		outside_circular_pitch,
		pressure_angle,
		clearance,
		bore_diameter,
		involute_facets,
		finish);

	// Pitch diameter: Diameter of pitch circle at the fat end of the gear.
	outside_pitch_diameter  =  number_of_teeth * outside_circular_pitch / 180;
	outside_pitch_radius = outside_pitch_diameter / 2;

	// The height of the pitch apex.
	pitch_apex = sqrt (pow (cone_distance, 2) - pow (outside_pitch_radius, 2));
	pitch_angle = asin (outside_pitch_radius/cone_distance);

	echo ("Num Teeth:", number_of_teeth, " Pitch Angle:", pitch_angle);

	finish = (finish != -1) ? finish : (pitch_angle < 45) ? bevel_gear_flat : bevel_gear_back_cone;

	apex_to_apex=cone_distance / cos (pitch_angle);
	back_cone_radius = apex_to_apex * sin (pitch_angle);

	// Calculate and display the pitch angle. This is needed to determine the angle to mount two meshing cone gears.

	// Base Circle for forming the involute teeth shape.
	base_radius = back_cone_radius * cos (pressure_angle);

	// Diametrial pitch: Number of teeth per unit length.
	pitch_diametrial = number_of_teeth / outside_pitch_diameter;

	// Addendum: Radial distance from pitch circle to outside circle.
	addendum = 1 / pitch_diametrial;
	// Outer Circle
	outer_radius = back_cone_radius + addendum;

	// Dedendum: Radial distance from pitch circle to root diameter
	dedendum = addendum + clearance;
	dedendum_angle = atan (dedendum / cone_distance);
	root_angle = pitch_angle - dedendum_angle;

	root_cone_full_radius = tan (root_angle)*apex_to_apex;
	back_cone_full_radius=apex_to_apex / tan (pitch_angle);

	back_cone_end_radius =
		outside_pitch_radius -
		dedendum * cos (pitch_angle) -
		gear_thickness / tan (pitch_angle);
	back_cone_descent = dedendum * sin (pitch_angle) + gear_thickness;

	// Root diameter: Diameter of bottom of tooth spaces.
	root_radius = back_cone_radius - dedendum;

	half_tooth_thickness = outside_pitch_radius * sin (360 / (4 * number_of_teeth)) - backlash / 4;
	half_thick_angle = asin (half_tooth_thickness / back_cone_radius);

	face_cone_height = apex_to_apex-face_width / cos (pitch_angle);
	face_cone_full_radius = face_cone_height / tan (pitch_angle);
	face_cone_descent = dedendum * sin (pitch_angle);
	face_cone_end_radius =
		outside_pitch_radius -
		face_width / sin (pitch_angle) -
		face_cone_descent / tan (pitch_angle);

	// For the bevel_gear_flat finish option, calculate the height of a cube to select the portion of the gear that includes the full pitch face.
	bevel_gear_flat_height = pitch_apex - (cone_distance - face_width) * cos (pitch_angle);

//	translate([0,0,-pitch_apex])
	difference ()
	{
		intersection ()
		{
			union()
			{
				rotate (half_thick_angle)
				translate ([0,0,pitch_apex-apex_to_apex])
				cylinder ($fn=number_of_teeth*2, r1=root_cone_full_radius,r2=0,h=apex_to_apex);
				for (i = [1:number_of_teeth])
//				for (i = [1:1])
				{
					rotate ([0,0,i*360/number_of_teeth])
					{
						involute_bevel_gear_tooth (
							back_cone_radius = back_cone_radius,
							root_radius = root_radius,
							base_radius = base_radius,
							outer_radius = outer_radius,
							pitch_apex = pitch_apex,
							cone_distance = cone_distance,
							half_thick_angle = half_thick_angle,
							involute_facets = involute_facets);
					}
				}
			}

			if (finish == bevel_gear_back_cone)
			{
				translate ([0,0,-back_cone_descent])
				cylinder (
					$fn=number_of_teeth*2,
					r1=back_cone_end_radius,
					r2=back_cone_full_radius*2,
					h=apex_to_apex + back_cone_descent);
			}
			else
			{
				translate ([-1.5*outside_pitch_radius,-1.5*outside_pitch_radius,0])
				cube ([3*outside_pitch_radius,
					3*outside_pitch_radius,
					bevel_gear_flat_height]);
			}
		}

		if (finish == bevel_gear_back_cone)
		{
			translate ([0,0,-face_cone_descent])
			cylinder (
				r1=face_cone_end_radius,
				r2=face_cone_full_radius * 2,
				h=face_cone_height + face_cone_descent+pitch_apex);
		}

		translate ([0,0,pitch_apex - apex_to_apex])
		cylinder (r=bore_diameter/2,h=apex_to_apex);
	}
}

module involute_bevel_gear_tooth (
	back_cone_radius,
	root_radius,
	base_radius,
	outer_radius,
	pitch_apex,
	cone_distance,
	half_thick_angle,
	involute_facets)
{
//	echo ("involute_bevel_gear_tooth",
//		back_cone_radius,
//		root_radius,
//		base_radius,
//		outer_radius,
//		pitch_apex,
//		cone_distance,
//		half_thick_angle);

	min_radius = max (base_radius*2,root_radius*2);

	pitch_point =
		involute (
			base_radius*2,
			involute_intersect_angle (base_radius*2, back_cone_radius*2));
	pitch_angle = atan2 (pitch_point[1], pitch_point[0]);
	centre_angle = pitch_angle + half_thick_angle;

	start_angle = involute_intersect_angle (base_radius*2, min_radius);
	stop_angle = involute_intersect_angle (base_radius*2, outer_radius*2);

	res=(involute_facets!=0)?involute_facets:($fn==0)?5:$fn/4;

	translate ([0,0,pitch_apex])
	rotate ([0,-atan(back_cone_radius/cone_distance),0])
	translate ([-back_cone_radius*2,0,-cone_distance*2])
	union ()
	{
		for (i=[1:res])
		{
			let (
				point1=	involute (base_radius*2,start_angle+(stop_angle - start_angle)*(i-1)/res),
				point2=	involute (base_radius*2,start_angle+(stop_angle - start_angle)*(i)/res),
				side1_point1= rotate_2dvector (centre_angle, point1),
				side1_point2= rotate_2dvector (centre_angle, point2),
				side2_point1= mirror_2dvector (rotate_2dvector (centre_angle, point1)),
				side2_point2= mirror_2dvector (rotate_2dvector (centre_angle, point2))
			)
			polyhedron (
				points=[
					[back_cone_radius*2+0.1,0,cone_distance*2],
					[side1_point1[0],side1_point1[1],0],
					[side1_point2[0],side1_point2[1],0],
					[side2_point2[0],side2_point2[1],0],
					[side2_point1[0],side2_point1[1],0],
					[0.1,0,0]],
				faces=[[0,2,1],[0,3,2],[0,4,3],[0,1,5],[1,2,5],[2,3,5],[3,4,5],[0,5,4]]
			);
		}
	}
}



module gear (
	number_of_teeth=15,
	circular_pitch=undef, diametral_pitch=undef,
	pressure_angle=28,
	clearance = undef,
	gear_thickness=5,
	rim_thickness=undef,
	rim_width=undef,
	hub_thickness=undef,
	hub_diameter=undef,
	bore_diameter=undef,
	circles=0,
	backlash=0,
	twist=0,
	helix_angle=0,
	herringbone=false,
	involute_facets=0,
	flat=false,
	roundsize=1,
	internal = false)
{
	// Check for undefined circular pitch (happens when neither circular_pitch or diametral_pitch are specified)
	if (circular_pitch==undef)
		echo("MCAD ERROR: gear module needs either a diametral_pitch or circular_pitch");

	//Convert diametrial pitch to our native circular pitch
	circular_pitch = (circular_pitch!=undef?circular_pitch:pi/diametral_pitch);

	// Calculate default clearance if not specified
	clearance = (clearance!=undef?clearance:0.25 * circular_pitch / pi);

	// Pitch diameter: Diameter of pitch circle.
	pitch_diameter  =  number_of_teeth * circular_pitch / pi;
	pitch_radius = pitch_diameter/2;
	pitch_circumference = PI * pitch_diameter;
	echo (str("Teeth: ", number_of_teeth, ", Pitch Radius: ", pitch_radius, ", Clearance: ", clearance));

	twist = (
		(twist != 0) ? twist :
		(tan (helix_angle) * rim_thickness /
			pitch_circumference * 360)
	);
	echo ("Twist: ", twist);

	// Base Circle
	base_radius = pitch_radius*cos(pressure_angle);

	// Diametrial pitch: Number of teeth per unit length.
	pitch_diametrial = number_of_teeth / pitch_diameter;

	// Addendum: Radial distance from pitch circle to outside circle.
	addendum = 1/pitch_diametrial + (internal ? clearance : 0);

	//Outer Circle
	outer_radius = pitch_radius+addendum;

	// Dedendum: Radial distance from pitch circle to root diameter
	dedendum = addendum + (internal ? -clearance : clearance);

	// Root diameter: Diameter of bottom of tooth spaces.
	root_radius = pitch_radius-dedendum;
	backlash_angle = (internal ? -backlash : backlash) / pitch_radius * 180 / pi;
	half_thick_angle = (360 / number_of_teeth - backlash_angle) / 4;

	// Variables controlling the rim.
	rim_thickness = (
        (rim_thickness != undef) ?
            (
                (rim_thickness != 0) ?
                    rim_thickness :
                    gear_thickness
            ) :
            gear_thickness * 1.5
    );
	rim_width = (rim_width != undef) ? rim_width : root_radius * .1;
	rim_radius = internal ? outer_radius + rim_width : root_radius - rim_width;

	// Variables controlling the hub_diameter
	hub_thickness = (
        (hub_thickness != undef) ?
        ((hub_thickness != 0) ? hub_thickness : gear_thickness) :
        gear_thickness * 2
    );
	hub_diameter = (hub_diameter != undef) ? hub_diameter : root_radius * .3;

	// Variables controlling the bore
	bore_diameter = (bore_diameter != undef) ? bore_diameter : root_radius * .1;

	// Variables controlling the circular holes in the gear.
	circle_orbit_diameter=hub_diameter/2+min(rim_radius, root_radius);
	circle_orbit_curcumference=pi*circle_orbit_diameter;

	max_thickness = max (rim_thickness, hub_thickness, gear_thickness);

	// Limit the circle size to 90% of the gear face.
	circle_diameter=
		min (
			0.70*circle_orbit_curcumference/circles,
			(min(rim_radius, root_radius)-hub_diameter/2)*0.9);

	module flat_gear ()
	{
		module _gear_shape ()
		{
			gear_shape (
				number_of_teeth,
				pitch_radius = pitch_radius,
				root_radius = root_radius,
				base_radius = base_radius,
				outer_radius = outer_radius,
				half_thick_angle = half_thick_angle,
				involute_facets=involute_facets);
		}n

		module rounding_circles ()
		{
			path_radius = internal ? outer_radius : root_radius;
                        circle_positions = (internal ?
                            [0:1:number_of_teeth] :
                            [0.5:1:number_of_teeth - 0.5]);

                        if (roundsize > 0)
                        for (i=circle_positions) {
                            rotate([0, 0, (i*360/number_of_teeth)])
                            translate([path_radius, 0])
                            circle(r=((360/number_of_teeth - half_thick_angle)/360) * pi*root_radius/2 * roundsize, $fa = 18, $fs = 0.5);
                        }
		}

		if (internal) {
			_gear_shape ();
			rounding_circles ();
		} else {
			difference() {
				_gear_shape ();
				rounding_circles ();
			}
		}
	}

	// render the extruded gear shape (or cutout for internal gear)
	module extruded_gear ()
	{
		lower_rim_thickness = (
			rim_thickness / 2 +
			((internal && gear_thickness == 0) ? 0.1 : 0)
		);
		lower_twist = twist / rim_thickness * lower_rim_thickness;

		upper_rim_thickness = (
			rim_thickness / 2 +
			((internal) ? 0.1 : 0)
		);
		upper_twist = twist / rim_thickness * upper_rim_thickness;

		if (flat) {
			flat_gear ();

		} else if (herringbone) {
			translate ([0, 0, rim_thickness / 2]) {
				linear_extrude (
					height = upper_rim_thickness,
					convexity = 10,
					twist = upper_twist
				)
				flat_gear ();

				mirror ([0, 0, 1])
				linear_extrude (
					height = lower_rim_thickness,
					convexity = 10,
					twist = lower_twist
				)
				flat_gear ();
			}

		} else {
			linear_extrude(
				height = rim_thickness + (internal ? 0.2 : 0),
				convexity = 10,
				twist = twist
			)
			flat_gear ();
		}
	}

	module ensure_rim ()
	{
		if (flat) {
			children ();

		} else if (internal) {
			difference () {
				linear_extrude (height = rim_thickness)
				circle (r = rim_radius);

				translate ([0, 0, gear_thickness])
				children ();
			}

		} else if (gear_thickness > rim_thickness) {
			union () {
				children ();

				linear_extrude_flat_option (
					flat = flat,
					height = gear_thickness
				)
				circle (r = rim_radius);
			}
		} else {
			difference () {
				children ();

				translate ([0, 0, gear_thickness])
				linear_extrude_flat_option (
					flat = flat,
					height = (rim_thickness - gear_thickness
						+ 0.1)
				)
				circle (r = rim_radius);
			}
		}
	}

	module hub ()
	{
		if (internal)
		cylinder (d=hub_diameter, h=hub_thickness);

		else if (!flat)
		translate ([0, 0, gear_thickness])
		cylinder (d=hub_diameter, h=hub_thickness - gear_thickness);
	}

	module _circles ()
	{
		if (circles > 1)
		for (i=[0:circles-1])
		rotate ([0, 0, i*360/circles])
		translate ([circle_orbit_diameter / 2, 0, 0])
		circle (r=circle_diameter / 2);
	}

	module bore ()
	{
		circle (d = bore_diameter);
	}

	difference () {
		union () {
			ensure_rim ()
			extruded_gear ();

			hub ();
		}

		linear_extrude_flat_option (
			flat = flat,
			center = true,
			height = (max_thickness + 0.1) * 2
		)
		union () {
			_circles ();
			bore ();
		}
	}
}

module rack(
		number_of_teeth=15,
		circular_pitch=false, diametral_pitch=false,
		pressure_angle=28,
		clearance=0.2,
		rim_thickness=8,
		rim_width=5,
		flat=false)
{

	if (circular_pitch==false && diametral_pitch==false)
		echo("MCAD ERROR: gear module needs either a diametral_pitch or circular_pitch");

	//Convert diametrial pitch to our native circular pitch
	circular_pitch = (circular_pitch!=false?circular_pitch:180/diametral_pitch);
	pitch = circular_pitch / 180 * PI;

	addendum = circular_pitch / 180;
	dedendum = addendum + clearance;
	pitch_slope = tan(pressure_angle);

	linear_extrude_flat_option(flat=flat, height=rim_thickness)
		union()
		{
			translate([0,-dedendum-rim_width/2])
				square([number_of_teeth*pitch, rim_width],center=true);

			p1 = pitch / 4 + pitch_slope * dedendum;
			p2 = pitch / 4 - pitch_slope * addendum;
			for(i=[1:number_of_teeth])
				translate([pitch*(i-number_of_teeth/2-0.5),0])
					polygon(points=[
							[-p1,-dedendum],
							[p1,-dedendum],
							[p2,addendum],
							[-p2,addendum]
					]);
		}
}

module linear_extrude_flat_option(flat =false, height = 10, center = false, convexity = 2, twist = 0)
{
	if(flat==false)
	{
		linear_extrude(height = height, center = center, convexity = convexity, twist= twist)
		children ();
	}
	else
	{
		children ();
	}

}


module gear_shape (
	number_of_teeth,
	pitch_radius,
	root_radius,
	base_radius,
	outer_radius,
	half_thick_angle,
	involute_facets)
{


	union()
	{
		rotate (half_thick_angle) circle ($fn=number_of_teeth*2, r=root_radius);

		for (i = [1:number_of_teeth])
		{
			
			rotate ([0,0,i*360/number_of_teeth])
			{
				involute_gear_tooth (
					pitch_radius = pitch_radius,
					root_radius = root_radius,
					base_radius = base_radius,
					outer_radius = outer_radius,
					half_thick_angle = half_thick_angle,
					involute_facets=involute_facets);
			}
		}
	}
}


module involute_gear_tooth (
	pitch_radius,
	root_radius,
	base_radius,
	outer_radius,
	half_thick_angle,
	involute_facets)
{
	min_radius = max (base_radius,root_radius);

	pitch_point = involute (base_radius, involute_intersect_angle (base_radius, pitch_radius));
	pitch_angle = atan2 (pitch_point[1], pitch_point[0]);
	centre_angle = pitch_angle + half_thick_angle;

	start_angle = involute_intersect_angle (base_radius, min_radius);
	stop_angle = involute_intersect_angle (base_radius, outer_radius);

	res=(involute_facets!=0)?involute_facets:($fn==0)?5:$fn/4;

	function reverse (v) = [
		for (i = [1:len (v)])
		v[len (v) - i]
	];

	side1_points = [
		for (i = [0:res])
		rotate_2dvector (centre_angle, involute (base_radius, start_angle + (stop_angle - start_angle) * i / res))
	];

	side2_points = [
		for (i = reverse (side1_points))
		mirror_2dvector (i)
	];

	polygon (points = concat ([[0, 0]], side1_points, side2_points));
}

// Mathematical Functions
//===============

// Finds the angle of the involute about the base radius at the given distance (radius) from it's center.
//source: http://www.mathhelpforum.com/math-help/geometry/136011-circle-involute-solving-y-any-given-x.html

function involute_intersect_angle (base_radius, radius) = sqrt (pow (radius/base_radius, 2) - 1) * 180 / pi;

// Calculate the involute position for a given base radius and involute angle.

function rotated_involute (rotate, base_radius, involute_angle) =
[
	cos (rotate) * involute (base_radius, involute_angle)[0] + sin (rotate) * involute (base_radius, involute_angle)[1],
	cos (rotate) * involute (base_radius, involute_angle)[1] - sin (rotate) * involute (base_radius, involute_angle)[0]
];

function involute (base_radius, involute_angle) =
[
	base_radius*(cos (involute_angle) + involute_angle*pi/180*sin (involute_angle)),
	base_radius*(sin (involute_angle) - involute_angle*pi/180*cos (involute_angle))
];

// For ease of conversion from proper circular pitch to this broken library's
// values
function convertcp (circular_pitch) = circular_pitch / PI * 180;
function circumference2radius (circumference) = circumference / (2 * PI);
function gear_spacing (cp, nt1, nt2) = circumference2radius (cp * nt1) +
                                       circumference2radius (cp * nt2);


// Test Cases
//===============

module test_gears()
{
	translate([17,-15])
	{
		#gear (number_of_teeth=17,
			circular_pitch=500,
			circles=8);

		rotate ([0,0,360*4/17])
		translate ([39.088888,0,0])
		{
			#gear (number_of_teeth=11,
				circular_pitch=500,
				hub_diameter=0,
				rim_width=65);
			translate ([0,0,8])
			{
				gear (number_of_teeth=6,
					circular_pitch=300,
					hub_diameter=0,
					rim_width=5,
					rim_thickness=6,
					pressure_angle=31);
				#rotate ([0,0,360*5/6])
				translate ([22.5,0,1])
				gear (number_of_teeth=21,
					circular_pitch=300,
					bore_diameter=2,
					hub_diameter=4,
					rim_width=1,
					hub_thickness=4,
					rim_thickness=4,
					gear_thickness=3,
					pressure_angle=31);
			}
		}

		translate ([-61.1111111,0,0])
		{
			#gear (number_of_teeth=27,
				circular_pitch=500,
				circles=5,
				hub_diameter=2*8.88888889);

			translate ([-37.5,0,0])
			rotate ([0,0,-90])
			rack (
				circular_pitch=500
			     );

			translate ([0,0,10])
			{
				gear (
					number_of_teeth=14,
					circular_pitch=200,
					pressure_angle=5,
					clearance = 0.2,
					gear_thickness = 10,
					rim_thickness = 10,
					rim_width = 15,
					bore_diameter=5,
					circles=0);
				translate ([13.8888888,0,1])
				#gear (
					number_of_teeth=11,
					circular_pitch=200,
					pressure_angle=5,
					clearance = 0.2,
					gear_thickness = 10,
					rim_thickness = 10,
					rim_width = 15,
					hub_thickness = 20,
					hub_diameter=2*7.222222,
					bore_diameter=5,
					circles=0);
			}
		}

		rotate ([0,0,360*-5/17])
		translate ([44.444444444,0,0])
		#gear (number_of_teeth=15,
			circular_pitch=500,
			hub_diameter=10,
			rim_width=5,
			rim_thickness=5,
			gear_thickness=4,
			hub_thickness=6,
			circles=9);

		rotate ([0,0,360*-1/17])
		translate ([30.5555555,0,-1])
		#gear (number_of_teeth=5,
			circular_pitch=500,
			hub_diameter=0,
			rim_width=5,
			rim_thickness=10);
	}
}

module meshing_double_helix ()
{
	test_double_helix_gear ();

	mirror ([0,1,0])
	translate ([58.33333333,0,0])
	test_double_helix_gear (teeth=13,circles=6);
}

module test_double_helix_gear (
	teeth=17,
	circles=8)
{
	//double helical gear
	{
		twist=200;
		height=20;
		pressure_angle=30;

		gear (number_of_teeth=teeth,
			circular_pitch=700,
			pressure_angle=pressure_angle,
			clearance = 0.2,
			gear_thickness = height/2*0.5,
			rim_thickness = height/2,
			rim_width = 5,
			hub_thickness = height/2*1.2,
			hub_diameter=15,
			bore_diameter=5,
			circles=circles,
			helix_angle=45,
		herringbone=true);
		*mirror([0,0,1])
		gear (number_of_teeth=teeth,
			circular_pitch=700,
			pressure_angle=pressure_angle,
			clearance = 0.2,
			gear_thickness = height/2,
			rim_thickness = height/2,
			rim_width = 5,
			hub_thickness = height/2,
			hub_diameter=15,
			bore_diameter=5,
			circles=circles,
			twist=twist/teeth);
	}
}

module test_backlash ()
{
	backlash = 2;
	teeth = 15;

	translate ([-29.166666,0,0])
	{
		translate ([58.3333333,0,0])
		rotate ([0,0,-360/teeth/4])
		gear (
			number_of_teeth = teeth,
			circular_pitch=700,
			gear_thickness = 12,
			rim_thickness = 15,
			rim_width = 5,
			hub_thickness = 17,
			hub_diameter=15,
			bore_diameter=5,
			backlash = 2,
			circles=8);

		rotate ([0,0,360/teeth/4])
		gear (
			number_of_teeth = teeth,
			circular_pitch=700,
			gear_thickness = 12,
			rim_thickness = 15,
			rim_width = 5,
			hub_thickness = 17,
			hub_diameter=15,
			bore_diameter=5,
			backlash = 2,
			circles=8);
	}

	color([0,0,128,0.5])
	translate([0,0,-5])
	cylinder ($fn=20,r=backlash / 4,h=25);
}

module test_internal_gear ()
{
	gear (
		number_of_teeth = 30,
		circular_pitch = 5 * 180 / PI,
		hub_thickness = 0,
		rim_thickness = 10,
		rim_width = 5,
		gear_thickness = 0,
		internal = true,
		helix_angle = 45,
		herringbone = true
	);
}

*test_internal_gear ();
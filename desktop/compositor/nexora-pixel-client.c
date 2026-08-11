/*
 * NEXORA pixel client — Wayland shared-memory render client (Phase 2).
 *
 * Connects to the running Wayland compositor, creates an ARGB8888 buffer
 * containing a distinctive two-colour checkerboard, attaches it to a surface
 * and commits it. It waits for the frame callback (the compositor has really
 * presented the buffer) and then prints NEXORA_PIXEL_CLIENT_OK.
 *
 * This is a real rendering round-trip used by the graphical gate: the QEMU
 * screendump must show the checkerboard, proving the compositor actually
 * renders frames, not merely that a process started.
 *
 * Build inside the image (libwayland-dev + gcc):
 *   wayland-scanner client-header /usr/share/wayland/wayland.xml wayland-protocol.h
 *   gcc -O2 -Wall -I. -o nexora-pixel-client nexora-pixel-client.c -lwayland-client
 */
#define _GNU_SOURCE
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

#include <wayland-client.h>
#include "wayland-protocol.h"

#define WIDTH 640
#define HEIGHT 400
#define SQUARE 40

static struct wl_compositor *compositor;
static struct wl_shm *shm;

static void
registry_global(void *data, struct wl_registry *registry, uint32_t name,
                const char *interface, uint32_t version)
{
	(void)data;
	(void)version;
	if (strcmp(interface, wl_compositor_interface.name) == 0) {
		compositor = wl_registry_bind(registry, name,
		                              &wl_compositor_interface, 1);
	} else if (strcmp(interface, wl_shm_interface.name) == 0) {
		shm = wl_registry_bind(registry, name, &wl_shm_interface, 1);
	}
}

static void
registry_global_remove(void *data, struct wl_registry *registry, uint32_t name)
{
	(void)data;
	(void)registry;
	(void)name;
}

static const struct wl_registry_listener registry_listener = {
	registry_global,
	registry_global_remove,
};

static void
frame_done(void *data, struct wl_callback *callback, uint32_t time)
{
	int *done = data;
	(void)time;
	*done = 1;
	wl_callback_destroy(callback);
}

static const struct wl_callback_listener frame_listener = {
	frame_done,
};

int
main(void)
{
	struct wl_display *display = wl_display_connect(NULL);
	if (display == NULL) {
		fprintf(stderr, "nexora-pixel-client: cannot connect\n");
		return 1;
	}

	struct wl_registry *registry = wl_display_get_registry(display);
	wl_registry_add_listener(registry, &registry_listener, NULL);
	wl_display_roundtrip(display);
	if (compositor == NULL || shm == NULL) {
		fprintf(stderr, "nexora-pixel-client: compositor/shm missing\n");
		return 1;
	}

	char path[] = "/dev/shm/nexora-shm-XXXXXX";
	int fd = mkstemp(path);
	if (fd < 0) {
		perror("nexora-pixel-client: mkstemp");
		return 1;
	}
	unlink(path);

	const size_t stride = WIDTH * 4;
	const size_t size = stride * HEIGHT;
	if (ftruncate(fd, (off_t)size) != 0) {
		perror("nexora-pixel-client: ftruncate");
		return 1;
	}

	uint8_t *pixels = mmap(NULL, size, PROT_READ | PROT_WRITE,
	                       MAP_SHARED, fd, 0);
	if (pixels == MAP_FAILED) {
		perror("nexora-pixel-client: mmap");
		return 1;
	}

	for (int y = 0; y < HEIGHT; y++) {
		for (int x = 0; x < WIDTH; x++) {
			int block = ((x / SQUARE) + (y / SQUARE)) % 2;
			uint8_t *px = pixels + (y * WIDTH + x) * 4;
			/* ARGB8888 little-endian memory order: B,G,R,A */
			if (block) {
				px[0] = 0xBB; px[1] = 0x44; px[2] = 0x11; px[3] = 0xFF;
			} else {
				px[0] = 0x00; px[1] = 0xAA; px[2] = 0xFF; px[3] = 0xFF;
			}
		}
	}

	struct wl_shm_pool *pool = wl_shm_create_pool(shm, fd, (int32_t)size);
	struct wl_buffer *buffer = wl_shm_pool_create_buffer(
		pool, 0, WIDTH, HEIGHT, (int32_t)stride, WL_SHM_FORMAT_ARGB8888);
	wl_shm_pool_destroy(pool);

	struct wl_surface *surface = wl_compositor_create_surface(compositor);
	int done = 0;
	struct wl_callback *callback = wl_surface_frame(surface);
	wl_callback_add_listener(callback, &frame_listener, &done);

	wl_surface_attach(surface, buffer, 0, 0);
	wl_surface_commit(surface);

	while (!done && wl_display_dispatch(display) != -1) {
	}

	wl_buffer_destroy(buffer);
	wl_surface_destroy(surface);
	wl_display_disconnect(display);
	munmap(pixels, size);
	close(fd);

	if (!done) {
		fprintf(stderr, "nexora-pixel-client: no frame presented\n");
		return 1;
	}

	printf("NEXORA_PIXEL_CLIENT_OK\n");
	return 0;
}
